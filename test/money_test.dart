import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:budget_buddy/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// C4 — money is integer minor units.
///
/// Started life red against the float implementation (commit "pin the C4
/// float-money defects"); the four original cases are still here, now passing,
/// alongside the round-trip, parse and total-correctness pack.
void main() {
  final usd = CurrencyUtils.resolve('USD');
  final jpy = CurrencyUtils.resolve('JPY');
  final krw = CurrencyUtils.resolve('KRW');
  final vnd = CurrencyUtils.resolve('VND');
  final pkr = CurrencyUtils.resolve('PKR');

  TransactionItem tx(int amountMinor) => TransactionItem(
        id: 'x',
        categoryId: 'c',
        amountMinor: amountMinor,
        note: '',
        date: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

  group('the C4 defects, fixed', () {
    test('ten 0.10 transactions total exactly 1.00', () {
      final total =
          List.generate(10, (_) => tx(10)).fold(0, (s, t) => s + t.amountMinor);

      expect(total, 100);
      expect(CurrencyUtils.formatAmount(total, usd), '\$1.00');
      // The float version of this sum was 0.9999999999999999.
      expect(List.generate(10, (_) => 0.10).fold(0.0, (s, v) => s + v),
          isNot(1.00),
          reason: 'guards the reason this test exists');
    });

    test('income minus three 33.33 spends is exactly 0.01', () {
      const incomeMinor = 10000;
      final spent = [tx(3333), tx(3333), tx(3333)]
          .fold(0, (s, t) => s + t.amountMinor);

      expect(incomeMinor - spent, 1);
      expect(CurrencyUtils.formatAmount(incomeMinor - spent, usd), '\$0.01');
    });

    test('a zero-decimal currency shows no decimal places', () {
      expect(CurrencyUtils.formatAmount(1234, jpy), '¥1,234');
      expect(CurrencyUtils.formatAmount(1234, krw), '₩1,234');
      expect(CurrencyUtils.formatAmount(1234, vnd), '₫1,234');
    });

    test('a 2-decimal currency rejects a 3-decimal amount', () {
      expect(Validators.amount(usd)('12.345'), 'Use at most 2 decimal places');
    });
  });

  group('currency table', () {
    test('all 23 currencies declare an ISO 4217 exponent', () {
      expect(CurrencyUtils.currencies, hasLength(23));
      for (final c in CurrencyUtils.currencies) {
        expect(c.decimalDigits, anyOf(0, 2, 3), reason: c.code);
      }
    });

    test('JPY, KRW and VND are the only zero-decimal members', () {
      final zeroDecimal = CurrencyUtils.currencies
          .where((c) => c.decimalDigits == 0)
          .map((c) => c.code)
          .toList();

      expect(zeroDecimal, ['JPY', 'KRW', 'VND']);
    });

    test('an unknown or missing code resolves to USD, never to a crash', () {
      expect(CurrencyUtils.resolve('XYZ').code, 'USD');
      expect(CurrencyUtils.resolve(null).code, 'USD');
      expect(CurrencyUtils.getByCode('XYZ'), isNull);
    });

    test('minorPerMajor follows the exponent', () {
      expect(CurrencyUtils.minorPerMajor(usd), 100);
      expect(CurrencyUtils.minorPerMajor(pkr), 100);
      expect(CurrencyUtils.minorPerMajor(jpy), 1);
      expect(CurrencyUtils.minorPerMajor(vnd), 1);
    });
  });

  group('minor <-> major round trip', () {
    test('2-decimal currency', () {
      for (final major in [0, 1, 7, 99, 500, 1234, 999999]) {
        final minor = CurrencyUtils.fromMajor(major, usd);
        expect(minor, major * 100);
        expect(CurrencyUtils.formatForInput(minor, usd), '$major');
        expect(CurrencyUtils.tryParseToMinor('$major', usd), minor);
      }
    });

    test('each zero-decimal currency keeps the number unscaled', () {
      for (final currency in [jpy, krw, vnd]) {
        for (final major in [0, 1, 500, 1234, 999999]) {
          final minor = CurrencyUtils.fromMajor(major, currency);
          expect(minor, major, reason: currency.code);
          expect(CurrencyUtils.formatForInput(minor, currency), '$major');
          expect(CurrencyUtils.tryParseToMinor('$major', currency), minor);
        }
      }
    });

    test('format -> parse is the identity for arbitrary minor values', () {
      const samples = [0, 1, 5, 99, 100, 101, 1000, 123456, 100000001];
      for (final currency in [usd, pkr, jpy, krw, vnd]) {
        for (final minor in samples) {
          final text = CurrencyUtils.formatForInput(minor, currency);
          expect(CurrencyUtils.tryParseToMinor(text, currency), minor,
              reason: '${currency.code} $minor -> "$text"');
        }
      }
    });
  });

  group('parsing user input', () {
    test('reads decimals into minor units without touching a double', () {
      expect(CurrencyUtils.tryParseToMinor('0.01', usd), 1);
      expect(CurrencyUtils.tryParseToMinor('0.10', usd), 10);
      expect(CurrencyUtils.tryParseToMinor('.5', usd), 50);
      expect(CurrencyUtils.tryParseToMinor('12.3', usd), 1230);
      expect(CurrencyUtils.tryParseToMinor('12.34', usd), 1234);
      expect(CurrencyUtils.tryParseToMinor('5.', usd), 500);
      expect(CurrencyUtils.tryParseToMinor(' 7 ', usd), 700);
      expect(CurrencyUtils.tryParseToMinor('-2.50', usd), -250);
    });

    test('0.07 * 100 style values survive exactly', () {
      // double.parse('0.07') * 100 == 7.000000000000001.
      final minor = CurrencyUtils.tryParseToMinor('0.07', usd);
      expect(minor, 7);
      expect(minor! * 100, 700);
    });

    test('group separators are accepted only in runs of three', () {
      expect(CurrencyUtils.tryParseToMinor('1,234', usd), 123400);
      expect(CurrencyUtils.tryParseToMinor('1,234.56', usd), 123456);
      expect(CurrencyUtils.tryParseToMinor('1,234,567', jpy), 1234567);
      // "12,50" is a comma-decimal habit. Rejected, never read as 1250 —
      // a visible error beats a silent 100x.
      expect(CurrencyUtils.parseAmount('12,50', usd).error,
          AmountParseError.malformed);
      expect(CurrencyUtils.parseAmount('1,23,456', usd).error,
          AmountParseError.malformed);
    });

    test('rejects more precision than the currency has', () {
      expect(CurrencyUtils.parseAmount('12.345', usd).error,
          AmountParseError.tooPrecise);
      expect(CurrencyUtils.parseAmount('0.001', pkr).error,
          AmountParseError.tooPrecise);
      for (final currency in [jpy, krw, vnd]) {
        expect(CurrencyUtils.parseAmount('12.5', currency).error,
            AmountParseError.tooPrecise,
            reason: currency.code);
        expect(CurrencyUtils.parseAmount('12.0', currency).error,
            AmountParseError.tooPrecise,
            reason: '${currency.code}: even a zero decimal is not valid');
      }
    });

    test('rejects garbage, empties and oversized input', () {
      expect(CurrencyUtils.parseAmount(null, usd).error,
          AmountParseError.empty);
      expect(CurrencyUtils.parseAmount('', usd).error, AmountParseError.empty);
      expect(
          CurrencyUtils.parseAmount('   ', usd).error, AmountParseError.empty);
      for (final bad in ['abc', '1.2.3', '1e5', '\$5', '5%', '.', '-', '1..2']) {
        expect(CurrencyUtils.parseAmount(bad, usd).error,
            AmountParseError.malformed,
            reason: bad);
      }
      expect(CurrencyUtils.parseAmount('1234567890123456', usd).error,
          AmountParseError.tooLarge);
    });
  });

  group('validators', () {
    test('amount rejects blank, zero, negative and over-precise input', () {
      final validate = Validators.amount(usd);
      expect(validate(''), 'Amount is required');
      expect(validate(null), 'Amount is required');
      expect(validate('0'), 'Enter a valid amount');
      expect(validate('0.00'), 'Enter a valid amount');
      expect(validate('-5'), 'Enter a valid amount');
      expect(validate('abc'), 'Enter a valid amount');
      expect(validate('12.345'), 'Use at most 2 decimal places');
      expect(validate('1234567890123456'), 'Amount is too large');
      expect(validate('0.01'), isNull);
      expect(validate('1,234.56'), isNull);
    });

    test('amount tells a zero-decimal currency user why 12.5 is refused', () {
      expect(Validators.amount(jpy)('12.5'),
          'JPY amounts have no decimal places');
      expect(Validators.amount(jpy)('1250'), isNull);
    });

    test('amountOrZero accepts blank and zero but not nonsense', () {
      final validate = Validators.amountOrZero(usd);
      expect(validate(''), isNull);
      expect(validate(null), isNull);
      expect(validate('0'), isNull);
      expect(validate('-1'), 'Enter a valid amount');
      expect(validate('12.345'), 'Use at most 2 decimal places');
    });
  });

  group('display', () {
    test('groups thousands and keeps the currency exponent', () {
      expect(CurrencyUtils.formatAmount(0, usd), '\$0.00');
      expect(CurrencyUtils.formatAmount(5, usd), '\$0.05');
      expect(CurrencyUtils.formatAmount(123456789, usd), '\$1,234,567.89');
      expect(CurrencyUtils.formatAmount(50000, pkr), '₨500.00');
      expect(CurrencyUtils.formatAmount(1234567, vnd), '₫1,234,567');
    });

    test('the sign leads, so a negative reads as -\$12.50', () {
      expect(CurrencyUtils.formatAmount(-1250, usd), '-\$12.50');
      expect(CurrencyUtils.formatAmount(-1250, jpy), '-¥1,250');
    });

    test('compact rounds to whole major units', () {
      expect(CurrencyUtils.formatAmountCompact(125049, usd), '\$1,250');
      expect(CurrencyUtils.formatAmountCompact(125050, usd), '\$1,251');
      expect(CurrencyUtils.formatAmountCompact(1234, jpy), '¥1,234');
      expect(CurrencyUtils.formatAmountCompact(-150, usd), '-\$2');
    });

    test('formatForInput drops empty decimals and never shows a symbol', () {
      expect(CurrencyUtils.formatForInput(50000, usd), '500');
      expect(CurrencyUtils.formatForInput(50050, usd), '500.50');
      expect(CurrencyUtils.formatForInput(5, usd), '0.05');
      expect(CurrencyUtils.formatForInput(500, jpy), '500');
    });

    test('toMajor is only a chart-geometry helper', () {
      expect(CurrencyUtils.toMajor(12345, usd), 123.45);
      expect(CurrencyUtils.toMajor(500, jpy), 500.0);
    });
  });

  group('totals at integer scale', () {
    Category category(String id, int budgetMinor) => Category(
          id: id,
          name: id,
          budgetLimitMinor: budgetMinor,
          colorValue: 0,
          month: '2026-08',
          createdAt: DateTime(2026, 8, 1),
          updatedAt: DateTime(2026, 8, 1),
        );

    test('a long run of awkward amounts sums exactly', () {
      // 0.01 + 0.02 + ... + 1.00 = 5050 cents.
      final txs = List.generate(100, (i) => tx(i + 1));
      expect(txs.fold(0, (s, t) => s + t.amountMinor), 5050);

      // A hundred 1-cent transactions: 100 cents, exactly. The float fold of
      // the same money lands on 1.0000000000000007 — off by a cent once
      // rounded the wrong way, and never reconcilable.
      final penniesMinor =
          List.generate(100, (_) => tx(1)).fold(0, (s, t) => s + t.amountMinor);
      expect(penniesMinor, 100);
      expect(CurrencyUtils.formatAmount(penniesMinor, usd), '\$1.00');
      expect(List.generate(100, (_) => 0.01).fold(0.0, (s, v) => s + v),
          isNot(1.0),
          reason: 'guards the reason this test exists');
    });

    test('category spend and remaining are exact', () {
      final food = category('food', 10000);
      final txs = [
        tx(3333)..categoryId = 'food',
        tx(3333)..categoryId = 'food',
        tx(3333)..categoryId = 'food',
        tx(500)..categoryId = 'other',
      ];

      final spent = food.calculateTotalSpentMinor(txs);
      expect(spent, 9999);
      expect(food.calculateRemainingMinor(spent), 1);
      expect(food.calculatePercentage(spent), closeTo(99.99, 1e-9));
    });

    test('a zero budget percentage does not divide by zero', () {
      expect(category('c', 0).calculatePercentage(500), 0);
    });
  });
}
