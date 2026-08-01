import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// The month key is the join between a category (stamped at write) and its
/// transactions (derived at read). If the two ever produce different strings
/// for the same month, spending silently vanishes from its own budget.
void main() {
  group('monthKey', () {
    test('is zero-padded to YYYY-MM', () {
      expect(AppDateUtils.monthKey(DateTime(2026, 1, 1)), '2026-01');
      expect(AppDateUtils.monthKey(DateTime(2026, 9, 30)), '2026-09');
      expect(AppDateUtils.monthKey(DateTime(2026, 10, 1)), '2026-10');
      expect(AppDateUtils.monthKey(DateTime(2026, 12, 31)), '2026-12');
      expect(AppDateUtils.monthKey(DateTime(999, 3, 4)), '0999-03');
    });

    test('is the day-of-month and time invariant', () {
      expect(AppDateUtils.monthKey(DateTime(2026, 2, 1, 0, 0, 0)),
          AppDateUtils.monthKey(DateTime(2026, 2, 28, 23, 59, 59)));
    });

    test('stamp-at-write and derive-at-read agree', () {
      final date = DateTime(2026, 8, 14, 21, 30);
      expect(AppDateUtils.getMonthKeyFromDate(date), '2026-08');
      expect(AppDateUtils.getMonthKeyFromDate(date),
          AppDateUtils.monthKey(date));
    });

    test('getCurrentMonthKey matches monthKey(now)', () {
      final now = DateTime.now();
      expect(AppDateUtils.getCurrentMonthKey(),
          anyOf(AppDateUtils.monthKey(now),
              AppDateUtils.monthKey(now.add(const Duration(seconds: 2)))));
    });

    test('does not follow the ambient locale into non-ASCII digits', () {
      initializeDateFormatting();
      final date = DateTime(2026, 3, 1);

      // What the key would have been if it were still built with DateFormat:
      // several locales render digits in their own numerals, and such a key
      // would never match one already stored.
      expect(DateFormat('yyyy-MM', 'fa').format(date), isNot('2026-03'));
      expect(DateFormat('yyyy-MM', 'bn').format(date), isNot('2026-03'));

      final previous = Intl.defaultLocale;
      Intl.defaultLocale = 'fa';
      addTearDown(() => Intl.defaultLocale = previous);

      expect(AppDateUtils.monthKey(date), '2026-03');
      expect(AppDateUtils.getMonthKeyFromDate(date), '2026-03');
    });
  });

  group('previous / next', () {
    test('rolls over December to January', () {
      expect(AppDateUtils.getNextMonthKey('2026-12'), '2027-01');
      expect(AppDateUtils.getPreviousMonthKey('2027-01'), '2026-12');
    });

    test('keeps the zero padding at single-digit months', () {
      expect(AppDateUtils.getNextMonthKey('2026-08'), '2026-09');
      expect(AppDateUtils.getPreviousMonthKey('2026-10'), '2026-09');
      expect(AppDateUtils.getPreviousMonthKey('2026-02'), '2026-01');
    });

    test('next(previous(m)) == m for every month of a year', () {
      for (var month = 1; month <= 12; month++) {
        final key = AppDateUtils.monthKey(DateTime(2026, month));
        expect(AppDateUtils.getNextMonthKey(AppDateUtils.getPreviousMonthKey(key)),
            key);
      }
    });

    test('walking back 24 months lands two years earlier', () {
      var key = '2026-08';
      for (var i = 0; i < 24; i++) {
        key = AppDateUtils.getPreviousMonthKey(key);
      }
      expect(key, '2024-08');
    });

    test('an unparseable key is returned unchanged, never thrown on', () {
      for (final bad in ['', 'nope', '2026', '2026-13', '2026-00', '2026-xx']) {
        expect(AppDateUtils.getPreviousMonthKey(bad), bad, reason: bad);
        expect(AppDateUtils.getNextMonthKey(bad), bad, reason: bad);
      }
    });
  });

  group('parseMonthKey', () {
    test('reads a valid key to the first of the month', () {
      expect(AppDateUtils.parseMonthKey('2026-08'), DateTime(2026, 8, 1));
    });

    test('refuses out-of-range and malformed keys', () {
      expect(AppDateUtils.parseMonthKey('2026-13'), isNull);
      expect(AppDateUtils.parseMonthKey('2026-00'), isNull);
      expect(AppDateUtils.parseMonthKey('2026'), isNull);
      expect(AppDateUtils.parseMonthKey('2026-08-01'), isNull);
      expect(AppDateUtils.parseMonthKey(''), isNull);
    });
  });

  group('getLastNMonthKeys', () {
    test('returns n consecutive keys, newest first', () {
      final keys = AppDateUtils.getLastNMonthKeys(6);
      expect(keys, hasLength(6));
      for (var i = 0; i < keys.length - 1; i++) {
        expect(AppDateUtils.getPreviousMonthKey(keys[i]), keys[i + 1]);
      }
    });
  });
}
