import 'package:intl/intl.dart';

/// Dates, and the one place a month key is built.
///
/// A **month key** is the string `"YYYY-MM"` — zero-padded, four-digit year,
/// in the DEVICE-LOCAL timezone. Categories are stamped with one at write
/// time; a transaction's month is derived from its `date` at read time. Both
/// paths must produce byte-identical strings or a transaction silently drops
/// out of its own month, so every one of them goes through [monthKey].
///
/// [monthKey] is deliberately plain string arithmetic rather than
/// `DateFormat('yyyy-MM')`: `DateFormat` renders digits in the ambient locale,
/// and several real locales do not use ASCII ones — measured 2026-08-01,
/// `DateFormat('yyyy-MM')` returns `۲۰۲۶-۰۳` under `fa`, `٢٠٢٦-٠٣` under
/// `ar_EG`, `২০২৬-০৩` under `bn`. Setting `Intl.defaultLocale` (which the app
/// does not do today, but a localisation pass would) would silently start
/// writing keys that never match the ones already stored. The `DateFormat`
/// calls left below are all human-facing labels, where localisation is the
/// point.
class AppDateUtils {
  /// THE month-key builder. Device-local, zero-padded, ASCII.
  static String monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';

  static String getCurrentMonthKey() => monthKey(DateTime.now());

  static String getMonthKeyFromDate(DateTime date) => monthKey(date);

  /// `YYYY-MM-DD`, device-local, ASCII — the export's date column.
  ///
  /// Built ON TOP of [monthKey] rather than beside it, so a row's `date` and
  /// its `month` cannot disagree: the month column is literally the first
  /// seven characters of the date column, and `test/csv_export_test.dart`
  /// keeps that on the record. `DateFormat('yyyy-MM-dd')` is not an option for
  /// the same reason it is not one for [monthKey] — it renders digits in the
  /// ambient locale, and a CSV that changes its bytes with the phone's
  /// language is not a data export.
  static String isoDate(DateTime date) =>
      '${monthKey(date)}-${date.day.toString().padLeft(2, '0')}';

  /// Parses a month key back to the first of that month, or null if the string
  /// is not one. Callers decide what an unparseable key means.
  static DateTime? parseMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return null;
    if (month < 1 || month > 12) return null;
    return DateTime(year, month);
  }

  /// The month before [monthKeyString], rolling the year over at January.
  /// An unparseable key is returned unchanged rather than throwing.
  static String getPreviousMonthKey(String monthKeyString) =>
      _shiftMonth(monthKeyString, -1);

  /// The month after [monthKeyString], rolling the year over at December.
  static String getNextMonthKey(String monthKeyString) =>
      _shiftMonth(monthKeyString, 1);

  /// [n] month keys ending with the current month, newest first.
  static List<String> getLastNMonthKeys(int n) {
    final now = DateTime.now();
    return List.generate(n, (i) => monthKey(DateTime(now.year, now.month - i)));
  }

  /// `DateTime` normalises month 0 to December of the previous year and month
  /// 13 to January of the next, so the rollover needs no special case.
  static String _shiftMonth(String monthKeyString, int delta) {
    final parsed = parseMonthKey(monthKeyString);
    if (parsed == null) return monthKeyString;
    return monthKey(DateTime(parsed.year, parsed.month + delta));
  }

  // --- Human-facing labels (localised on purpose) ---------------------------

  static String formatMonthKey(String monthKeyString) {
    final parsed = parseMonthKey(monthKeyString);
    if (parsed == null) return monthKeyString;
    return DateFormat('MMMM yyyy').format(parsed);
  }

  /// `Aug '26`. The apostrophe is deliberate: `MMM yy` renders "Aug 26",
  /// which reads as the 26th of August on a chart axis (UI-12). `''` is an
  /// escaped literal apostrophe in an ICU pattern; the rest stays localised.
  static String formatMonthShort(String monthKeyString) {
    final parsed = parseMonthKey(monthKeyString);
    if (parsed == null) return monthKeyString;
    return DateFormat("MMM ''yy").format(parsed);
  }

  static String formatDate(DateTime date) =>
      DateFormat('MMM dd, yyyy').format(date);

  static String formatDateShort(DateTime date) => DateFormat('MM/dd').format(date);
}
