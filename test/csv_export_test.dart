import 'dart:convert';
import 'dart:io';

import 'package:budget_buddy/core/constants/app_constants.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/services/app/csv_export.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// F-13 — the export, tested where an export actually breaks.
///
/// `buildCsv` is pure, so all of this runs without Hive, without a share sheet
/// and without a device: a note containing a comma, a note starting with `=`,
/// a currency with no decimal places, a phone set to Persian, a thousand rows,
/// and a tie in the sort order.
void main() {
  final pkr = CurrencyUtils.resolve('PKR');
  final jpy = CurrencyUtils.resolve('JPY');

  Category category({
    required String id,
    required String name,
    String month = '2026-08',
  }) =>
      Category(
        id: id,
        name: name,
        budgetLimitMinor: 100000,
        colorValue: 0xFF2D8B8B,
        iconCodePoint: 0xe56c,
        month: month,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

  TransactionItem transaction({
    required String id,
    required String categoryId,
    required DateTime date,
    int amountMinor = 245000,
    String note = '',
    DateTime? createdAt,
  }) =>
      TransactionItem(
        id: id,
        categoryId: categoryId,
        amountMinor: amountMinor,
        note: note,
        date: date,
        createdAt: createdAt ?? date,
        updatedAt: createdAt ?? date,
      );

  String csvOf({
    required List<TransactionItem> transactions,
    List<Category> categories = const [],
    Currency? currency,
  }) =>
      CsvExport.buildCsv(
        transactions: transactions,
        categories: categories,
        currency: currency ?? pkr,
      );

  /// Records, with the BOM stripped, split the way a reader splits them.
  List<String> recordsOf(String csv) =>
      csv.substring(1).split('\r\n');

  /// One record's fields, honouring RFC 4180 quoting — a real (small) parser,
  /// because splitting on commas would agree with a broken writer.
  List<String> fieldsOf(String record) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < record.length; i++) {
      final ch = record[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < record.length && record[i + 1] == '"') {
            buffer.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buffer.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }

  final food = category(id: 'food-aug', name: 'Food');

  group('the file a spreadsheet opens', () {
    test('T1: starts with the UTF-8 BOM bytes EF BB BF', () {
      final bytes = utf8.encode(csvOf(transactions: [
        transaction(id: 't1', categoryId: 'food-aug', date: DateTime(2026, 8, 4))
      ], categories: [
        food
      ]));

      expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
    });

    test('T2: names its columns in the agreed order', () {
      final csv = csvOf(transactions: const []);

      expect(recordsOf(csv).first, 'date,month,category,note,amount,currency');
    });

    test('T3: separates records with CRLF and ends without a blank line', () {
      final csv = csvOf(transactions: [
        transaction(id: 'a', categoryId: 'food-aug', date: DateTime(2026, 8, 4)),
        transaction(id: 'b', categoryId: 'food-aug', date: DateTime(2026, 8, 5)),
      ], categories: [
        food
      ]);

      expect(csv.endsWith('\r\n'), isFalse);
      expect(recordsOf(csv).length, 3);
      // No bare LF anywhere: every \n in the file is the tail of a \r\n.
      expect('\n'.allMatches(csv).length, '\r\n'.allMatches(csv).length);
    });

    test('T4: every row carries exactly six fields', () {
      final csv = csvOf(transactions: [
        transaction(
            id: 'a',
            categoryId: 'food-aug',
            date: DateTime(2026, 8, 4),
            note: 'plain'),
        transaction(
            id: 'b',
            categoryId: 'missing',
            date: DateTime(2026, 7, 30),
            note: 'with, comma'),
        transaction(id: 'c', categoryId: 'food-aug', date: DateTime(2026, 8, 6)),
      ], categories: [
        food
      ]);

      for (final record in recordsOf(csv)) {
        expect(fieldsOf(record).length, 6, reason: 'record: $record');
      }
    });

    test('T5: an empty note is an empty field, not a missing one', () {
      final csv = csvOf(transactions: [
        transaction(id: 'a', categoryId: 'food-aug', date: DateTime(2026, 8, 4))
      ], categories: [
        food
      ]);

      expect(fieldsOf(recordsOf(csv)[1])[3], '');
    });
  });

  group('quoting', () {
    test('T6: a note containing a comma stays ONE field', () {
      final csv = csvOf(transactions: [
        transaction(
            id: 'a',
            categoryId: 'food-aug',
            date: DateTime(2026, 8, 4),
            note: 'Weekly bazaar, groceries')
      ], categories: [
        food
      ]);

      final row = recordsOf(csv)[1];
      expect(row, contains('"Weekly bazaar, groceries"'));
      expect(fieldsOf(row).length, 6);
      expect(fieldsOf(row)[3], 'Weekly bazaar, groceries');
    });

    test('T7: a quote inside a note is doubled and survives the round trip', () {
      final csv = csvOf(transactions: [
        transaction(
            id: 'a',
            categoryId: 'food-aug',
            date: DateTime(2026, 8, 4),
            note: 'Said "cheap"')
      ], categories: [
        food
      ]);

      expect(recordsOf(csv)[1], contains('"Said ""cheap"""'));
      expect(fieldsOf(recordsOf(csv)[1])[3], 'Said "cheap"');
    });

    test('T8: a newline inside a note is preserved verbatim, not stripped', () {
      final csv = csvOf(transactions: [
        transaction(
            id: 'a',
            categoryId: 'food-aug',
            date: DateTime(2026, 8, 4),
            note: 'line one\nline two')
      ], categories: [
        food
      ]);

      // The record itself spans two physical lines — which is why records are
      // counted by a parser, not by splitting the file on newlines.
      expect(csv, contains('"line one\nline two"'));
    });

    test('T9: a lone carriage return is quoted and kept', () {
      final csv = csvOf(transactions: [
        transaction(
            id: 'a',
            categoryId: 'food-aug',
            date: DateTime(2026, 8, 4),
            note: 'before\rafter')
      ], categories: [
        food
      ]);

      expect(csv, contains('"before\rafter"'));
    });

    test('T10: a category name containing a comma is quoted too', () {
      final csv = csvOf(transactions: [
        transaction(id: 'a', categoryId: 'c1', date: DateTime(2026, 8, 4))
      ], categories: [
        category(id: 'c1', name: 'Bills, utilities')
      ]);

      expect(fieldsOf(recordsOf(csv)[1])[2], 'Bills, utilities');
    });
  });

  group('money', () {
    test('T11: amounts are plain major units, no symbol and no separators', () {
      final csv = csvOf(transactions: [
        transaction(
            id: 'a',
            categoryId: 'food-aug',
            date: DateTime(2026, 8, 4),
            amountMinor: 245000),
        transaction(
            id: 'b',
            categoryId: 'food-aug',
            date: DateTime(2026, 8, 5),
            amountMinor: 123456789),
      ], categories: [
        food
      ]);

      expect(fieldsOf(recordsOf(csv)[1])[4], '2450.00');
      expect(fieldsOf(recordsOf(csv)[2])[4], '1234567.89');
      expect(csv.contains('₨'), isFalse);
    });

    test('T12: a zero-decimal currency exports whole units, no decimal point',
        () {
      final csv = csvOf(
        transactions: [
          transaction(
              id: 'a',
              categoryId: 'food-aug',
              date: DateTime(2026, 8, 4),
              amountMinor: 1200)
        ],
        categories: [food],
        currency: jpy,
      );

      final row = fieldsOf(recordsOf(csv)[1]);
      expect(row[4], '1200');
      expect(row[5], 'JPY');
    });

    test('T13: trailing zeros are kept so the column has ONE format', () {
      // formatForInput would write "2450" here and "2450.50" below, which is
      // the mixed column this function exists to avoid.
      expect(CurrencyUtils.formatForExport(245000, pkr), '2450.00');
      expect(CurrencyUtils.formatForExport(245050, pkr), '2450.50');
      expect(CurrencyUtils.formatForExport(5, pkr), '0.05');
      expect(CurrencyUtils.formatForExport(0, pkr), '0.00');
    });
  });

  group('the columns that come from the data', () {
    test('T14: every row\'s month is the month key of its own date', () {
      final dates = [
        DateTime(2026, 8, 4),
        DateTime(2026, 7, 31, 23, 59),
        DateTime(2025, 12, 1),
      ];
      final csv = csvOf(
        transactions: [
          for (var i = 0; i < dates.length; i++)
            transaction(id: 't$i', categoryId: 'food-aug', date: dates[i])
        ],
        categories: [food],
      );

      for (final record in recordsOf(csv).skip(1)) {
        final fields = fieldsOf(record);
        expect(fields[1], fields[0].substring(0, 7),
            reason: 'the month column must be the date column\'s month');
      }
    });

    test('T15: isoDate and monthKey cannot drift apart', () {
      // The binding: the export's date column starts with its month column for
      // every date, including the ones that tempt an off-by-one.
      for (final d in [
        DateTime(2026, 1, 1),
        DateTime(2026, 12, 31),
        DateTime(2027, 2, 28),
        DateTime(2024, 2, 29),
        DateTime(999, 9, 9),
      ]) {
        expect(AppDateUtils.isoDate(d).startsWith(AppDateUtils.monthKey(d)),
            isTrue,
            reason: '$d');
        expect(AppDateUtils.isoDate(d).length, 10, reason: '$d');
      }
    });

    test('T16: a back-dated transaction exports under the month it counts in',
        () {
      // The F-01 case: the row belongs to July's clone, and the export must
      // agree with the dashboard that included it in July.
      final csv = csvOf(
        transactions: [
          transaction(
              id: 'back', categoryId: 'food-jul', date: DateTime(2026, 7, 14))
        ],
        categories: [
          category(id: 'food-jul', name: 'Food', month: '2026-07'),
          food,
        ],
      );

      final fields = fieldsOf(recordsOf(csv)[1]);
      expect(fields[0], '2026-07-14');
      expect(fields[1], '2026-07');
      expect(fields[2], 'Food');
    });

    test('T17: spend whose category is gone exports as Uncategorised', () {
      final csv = csvOf(
        transactions: [
          transaction(
              id: 'orphan',
              categoryId: 'deleted-forever',
              date: DateTime(2026, 8, 4))
        ],
        categories: [food],
      );

      expect(fieldsOf(recordsOf(csv)[1])[2], kUncategorisedCategoryName);
    });
  });

  group('order', () {
    test('T18: date ascending, then createdAt, then id — a three-way tie', () {
      final sameDate = DateTime(2026, 8, 4);
      final sameStamp = DateTime(2026, 8, 4, 10);
      final csv = csvOf(
        transactions: [
          // Deliberately shuffled, and deliberately sharing a createdAt the way
          // onboarding's seed rows do.
          transaction(
              id: 'c',
              categoryId: 'food-aug',
              date: sameDate,
              createdAt: sameStamp,
              note: 'c'),
          transaction(
              id: 'a',
              categoryId: 'food-aug',
              date: sameDate,
              createdAt: sameStamp,
              note: 'a'),
          transaction(
              id: 'b',
              categoryId: 'food-aug',
              date: sameDate,
              createdAt: sameStamp,
              note: 'b'),
          transaction(
              id: 'earlier-day',
              categoryId: 'food-aug',
              date: DateTime(2026, 8, 1),
              note: 'first'),
          transaction(
              id: 'later-stamp',
              categoryId: 'food-aug',
              date: sameDate,
              createdAt: DateTime(2026, 8, 4, 18),
              note: 'last'),
        ],
        categories: [food],
      );

      expect(recordsOf(csv).skip(1).map((r) => fieldsOf(r)[3]).toList(),
          ['first', 'a', 'b', 'c', 'last']);
    });

    test('T19: exporting does not reorder the caller\'s list', () {
      final list = [
        transaction(id: 'z', categoryId: 'food-aug', date: DateTime(2026, 8, 9)),
        transaction(id: 'a', categoryId: 'food-aug', date: DateTime(2026, 8, 1)),
      ];

      csvOf(transactions: list, categories: [food]);

      expect(list.map((t) => t.id).toList(), ['z', 'a'],
          reason: 'a live screen must not reshuffle because someone exported');
    });
  });

  group('CSV injection', () {
    test('T20: user text that starts a formula gets an apostrophe', () {
      for (final dangerous in ['=1+1', '+1', '-1', '@SUM(A1)', '\tx', '\rx']) {
        final csv = csvOf(
          transactions: [
            transaction(
                id: 'a',
                categoryId: 'food-aug',
                date: DateTime(2026, 8, 4),
                note: dangerous)
          ],
          categories: [food],
        );

        expect(fieldsOf(recordsOf(csv)[1])[3], "'$dangerous",
            reason: 'note "$dangerous"');
      }
    });

    test('T21: a dangerous CATEGORY name is defused too', () {
      final csv = csvOf(
        transactions: [
          transaction(id: 'a', categoryId: 'c1', date: DateTime(2026, 8, 4))
        ],
        categories: [category(id: 'c1', name: '=cmd|calc')],
      );

      expect(fieldsOf(recordsOf(csv)[1])[2], "'=cmd|calc");
    });

    test('T22: generated columns are NEVER prefixed — including a negative',
        () {
      final csv = csvOf(
        transactions: [
          transaction(
              id: 'a',
              categoryId: 'food-aug',
              date: DateTime(2026, 8, 4),
              amountMinor: -1200)
        ],
        categories: [food],
      );

      final fields = fieldsOf(recordsOf(csv)[1]);
      expect(fields[0], '2026-08-04');
      expect(fields[1], '2026-08');
      expect(fields[4], '-12.00', reason: 'an apostrophe here would be a lie');
      expect(fields[5], 'PKR');
    });

    test('T23: ordinary text is left exactly as typed', () {
      final csv = csvOf(
        transactions: [
          transaction(
              id: 'a',
              categoryId: 'food-aug',
              date: DateTime(2026, 8, 4),
              note: 'دودھ اور چائے 🍵')
        ],
        categories: [food],
      );

      expect(fieldsOf(recordsOf(csv)[1])[3], 'دودھ اور چائے 🍵');
    });
  });

  test('T24: the bytes are identical under en_US, fa, ar_EG and bn', () {
    // Not just "the digits are ASCII": byte equality also catches a flipped
    // decimal separator or group separator, which is how a locale-aware
    // formatter would break this file. Generated columns only — the note here
    // is deliberately ASCII, because a user's Urdu note is legitimately
    // non-ASCII and identical in every locale anyway.
    final transactions = [
      transaction(
          id: 'a',
          categoryId: 'food-aug',
          date: DateTime(2026, 8, 4),
          amountMinor: 123456789,
          note: 'monthly'),
      transaction(
          id: 'b',
          categoryId: 'food-aug',
          date: DateTime(2026, 12, 31),
          amountMinor: 5,
          note: 'tea'),
    ];

    final previous = Intl.defaultLocale;
    final byLocale = <String, List<int>>{};
    try {
      for (final locale in ['en_US', 'fa', 'ar_EG', 'bn']) {
        Intl.defaultLocale = locale;
        byLocale[locale] = utf8
            .encode(csvOf(transactions: transactions, categories: [food]));
      }
    } finally {
      Intl.defaultLocale = previous;
    }

    for (final locale in ['fa', 'ar_EG', 'bn']) {
      expect(byLocale[locale], byLocale['en_US'], reason: 'locale $locale');
    }
  });

  test('T25: a thousand rows build correctly and stay in order', () {
    final transactions = [
      for (var i = 0; i < 1000; i++)
        transaction(
          id: 'id-${i.toString().padLeft(4, '0')}',
          categoryId: 'food-aug',
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          amountMinor: 100 + i,
          note: 'row $i',
        )
    ];

    final csv = csvOf(transactions: transactions, categories: [food]);
    final records = recordsOf(csv);

    expect(records.length, 1001);
    expect(fieldsOf(records[1])[3], 'row 0');
    expect(fieldsOf(records[1000])[3], 'row 999');
    for (final record in records.skip(1)) {
      expect(fieldsOf(record).length, 6);
    }
  });

  group('delivery', () {
    test('T26: the file is named for the day it was made', () {
      expect(CsvExport.fileName(DateTime(2026, 8, 2, 23, 30)),
          'buddgetbuddy-export-20260802.csv');
    });

    test('T27: what lands on disk starts with the BOM', () async {
      final dir = await Directory.systemTemp.createTemp('buddgetbuddy_csv');
      addTearDown(() => dir.deleteSync(recursive: true));

      final csv = csvOf(transactions: [
        transaction(id: 'a', categoryId: 'food-aug', date: DateTime(2026, 8, 4))
      ], categories: [
        food
      ]);
      final file = await CsvExport.writeToTemp(csv,
          now: DateTime(2026, 8, 2), directory: dir);

      final bytes = await file.readAsBytes();
      expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
      expect(file.path, endsWith('buddgetbuddy-export-20260802.csv'));
      // Byte equality, not `utf8.decode(bytes) == csv`: Dart's UTF-8 decoder
      // silently swallows a leading BOM, so a string comparison would pass just
      // as happily on a file that had lost it.
      expect(bytes, utf8.encode(csv));
    });

    test('T28: exports are written to the temp directory, never to documents',
        () {
      // A source guard: the difference is invisible at runtime here but decides
      // whether every export joins the phone's backup set and iCloud (F-12
      // interlock).
      final source =
          File('lib/services/app/csv_export.dart').readAsStringSync();
      expect(source, contains('getTemporaryDirectory()'));
      expect(source.contains('getApplicationDocumentsDirectory'), isFalse);
    });
  });
}
