import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:budget_buddy/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// C4 — money must be integer minor units.
///
/// These tests are written against the behaviour the app is REQUIRED to have.
/// They fail against the float-based implementation on purpose: this file lands
/// red first so the defect is pinned in history, then the migration turns it
/// green.
void main() {
  TransactionItem tx(double amount) => TransactionItem(
        id: 'x',
        categoryId: 'c',
        amount: amount,
        note: '',
        date: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

  group('float drift (the C4 defect)', () {
    test('ten 0.10 transactions must total exactly 1.00', () {
      // Mirrors dashboard_controller.totalSpent: fold(0.0, (sum, t) => …).
      final txs = List.generate(10, (_) => tx(0.10));
      final total = txs.fold(0.0, (sum, t) => sum + t.amount);

      expect(total, 1.00,
          reason: 'IEEE-754 addition of 0.10 ten times yields '
              '0.9999999999999999 — money must not be a float');
    });

    test('income minus three 33.33 spends must be exactly 0.01', () {
      // Mirrors dashboard_controller.remaining: income - totalSpent.
      const income = 100.0;
      final spent = [tx(33.33), tx(33.33), tx(33.33)]
          .fold(0.0, (sum, t) => sum + t.amount);

      expect(income - spent, 0.01,
          reason: 'float subtraction leaves 0.010000000000005116');
    });
  });

  group('display', () {
    test('a zero-decimal currency (JPY) shows no decimal places', () {
      final jpy = CurrencyUtils.getByCode('JPY')!;

      // Today's formatter takes (double, symbol) and hardcodes 2dp, so it
      // cannot know JPY has none.
      expect(CurrencyUtils.formatAmount(1234, jpy.symbol), '¥1,234');
    });
  });

  group('input precision', () {
    test('a 2-decimal currency rejects a 3-decimal amount', () {
      // 12.345 USD is not representable in cents; accepting it stores
      // sub-minor precision that no display can ever show back.
      expect(Validators.amount('12.345'), isNotNull,
          reason: 'must be rejected with a validation message');
    });
  });
}
