import 'dart:io';
import 'dart:ui' show Rect;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_item.dart';
import '../../utils/currency_utils.dart';
import '../../utils/date_utils.dart';

/// "Can I get my data out?" — answered as a CSV a spreadsheet can open.
///
/// [buildCsv] is pure: models in, a `String` out, no clock, no Hive, no share
/// sheet. Everything that could go wrong with an export goes wrong in that
/// string — a note with a comma, a note starting with `=`, a currency with no
/// decimals, a phone set to Persian — so that is where the tests live
/// (`test/csv_export_test.dart`). The two functions below it only put the
/// string on disk and hand it to the platform.
class CsvExport {
  CsvExport._();

  /// The column order, and the contract with whoever opens the file.
  static const List<String> header = [
    'date',
    'month',
    'category',
    'note',
    'amount',
    'currency',
  ];

  /// A UTF-8 byte-order mark, written as the file's first three bytes.
  ///
  /// Not decoration: without it, Excel on a Windows machine reads a UTF-8 CSV
  /// in the legacy code page and turns every non-ASCII note into mojibake,
  /// which is the single most common "your export is garbage" report. Sheets,
  /// Numbers and pandas all tolerate it.
  /// Spelled as an escape, not pasted: the character itself is invisible in an
  /// editor, and an invisible character nobody can see is one a future edit
  /// deletes by accident.
  static const String _bom = '\u{FEFF}';

  /// RFC 4180 separates records with CRLF, and the last record's terminator is
  /// optional — so records are JOINED with it and the file does not end in a
  /// blank line.
  static const String _crlf = '\r\n';

  /// Characters that make a spreadsheet treat a text cell as a formula. Quoting
  /// alone does NOT stop this — a common and wrong assumption — so any user
  /// text starting with one gets a leading apostrophe.
  static const String _formulaStarters = '=+-@\t\r';

  /// Every transaction, all months, one row each.
  ///
  /// The category column is the name that category had IN THAT MONTH: each
  /// month holds its own clone, and a transaction points at the clone of its
  /// own date-month, so reading the name through the id gives the historical
  /// name for free. Spend whose category is gone is called "Uncategorised",
  /// the same answer attribution gives it.
  ///
  /// The currency column is the CURRENT setting for every row. The schema has
  /// no per-transaction currency, so this is a limitation being stated rather
  /// than a fact being claimed: rows entered before a currency change carry the
  /// new code.
  static String buildCsv({
    required List<TransactionItem> transactions,
    required List<Category> categories,
    required Currency currency,
  }) {
    final nameById = {for (final c in categories) c.id: c.name};

    // A copy: sorting the caller's list (often an RxList straight off a box
    // stream) would reorder a live screen as a side effect of exporting.
    final ordered = List<TransactionItem>.of(transactions)..sort(_exportOrder);

    // StringBuffer, not repeated concatenation: a thousand rows of `+=` is a
    // thousand intermediate strings.
    final buffer = StringBuffer()
      ..write(_bom)
      ..write(header.join(','));

    for (final t in ordered) {
      final name = nameById[t.categoryId] ?? kUncategorisedCategoryName;
      buffer
        ..write(_crlf)
        // Generated columns: ASCII by construction, and never given a formula
        // guard — an apostrophe in front of a date would corrupt the data to
        // protect against a risk that cannot exist here.
        ..write(_escape(AppDateUtils.isoDate(t.date)))
        ..write(',')
        ..write(_escape(AppDateUtils.monthKey(t.date)))
        ..write(',')
        // User text: escaped AND defused.
        ..write(_escape(_defuse(name)))
        ..write(',')
        ..write(_escape(_defuse(t.note)))
        ..write(',')
        // Minor units become major units exactly here, once, and nowhere
        // earlier: the export is the display boundary for this number.
        ..write(_escape(CurrencyUtils.formatForExport(t.amountMinor, currency)))
        ..write(',')
        ..write(_escape(currency.code));
    }

    return buffer.toString();
  }

  /// `buddgetbuddy-export-YYYYMMDD.csv`.
  static String fileName(DateTime now) =>
      'buddgetbuddy-export-${AppDateUtils.isoDate(now).replaceAll('-', '')}.csv';

  /// Writes [csv] to the TEMPORARY directory and returns the file.
  ///
  /// Temporary, never the documents directory, and this is a hard requirement
  /// rather than a preference: documents is exactly what the Android backup
  /// rules include and what iOS syncs to iCloud, so an export written there
  /// would quietly join every future backup. The share sheet copies what it
  /// needs; the OS reclaims the rest.
  ///
  /// [directory] exists so tests can watch the bytes land without a plugin.
  static Future<File> writeToTemp(
    String csv, {
    required DateTime now,
    Directory? directory,
  }) async {
    final dir = directory ?? await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}${fileName(now)}');
    // Default encoding is UTF-8, so the BOM character becomes EF BB BF.
    return file.writeAsString(csv, flush: true);
  }

  /// Hands [file] to the platform share sheet.
  ///
  /// [sharePositionOrigin] is required for iPad and Mac, where a share sheet is
  /// a popover that has to point at something; it is ignored elsewhere.
  static Future<void> share(File file, {Rect? sharePositionOrigin}) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: '${AppConstants.appName} export',
      sharePositionOrigin: sharePositionOrigin,
    ));
  }

  // --- Internals ------------------------------------------------------------

  /// date asc, then `createdAt` asc, then `id` asc.
  ///
  /// All three keys are needed for a deterministic file: onboarding writes its
  /// seed rows with one shared `createdAt`, so date+createdAt alone leaves ties
  /// that `List.sort` (not a stable sort) can order differently between runs.
  static int _exportOrder(TransactionItem a, TransactionItem b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    final byCreated = a.createdAt.compareTo(b.createdAt);
    if (byCreated != 0) return byCreated;
    return a.id.compareTo(b.id);
  }

  /// RFC 4180: quote a field containing a comma, a quote or a line break, and
  /// double any quote inside it.
  ///
  /// Line breaks are preserved verbatim, never stripped — a note typed across
  /// two lines is the user's data, and a blanket `replaceAll` would silently
  /// edit it. A lone CR counts too: some readers split on it.
  static String _escape(String field) {
    final needsQuotes = field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r');
    if (!needsQuotes) return field;
    return '"${field.replaceAll('"', '""')}"';
  }

  /// Prefixes user text that a spreadsheet would evaluate as a formula.
  ///
  /// USER-TEXT COLUMNS ONLY. The apostrophe is a display convention the
  /// spreadsheet consumes; putting one in front of a generated value would
  /// corrupt it.
  static String _defuse(String value) {
    if (value.isEmpty) return value;
    if (!_formulaStarters.contains(value[0])) return value;
    return "'$value";
  }
}
