import 'package:budget_buddy/data/predefined_categories.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:flutter_test/flutter_test.dart';

/// UI-35 — seed budgets follow the income the user just entered.
///
/// The presets used to seed currency-blind whole numbers (Housing 1200, Food
/// 500, Transport 200 …), which read as dollars and gave a PKR user a ₨200
/// monthly transport budget. Shares are integer percent, rounded DOWN to a
/// clean step, so the nine seeds always total less than the stated income.
void main() {
  final pkr = CurrencyUtils.resolve('PKR'); // 2 decimals
  final jpy = CurrencyUtils.resolve('JPY'); // 0 decimals
  final usd = CurrencyUtils.resolve('USD');

  PredefinedCategory preset(String name) =>
      kPredefinedCategories.firstWhere((p) => p.name == name);

  int seedTotal(int incomeMinor, Currency currency) => kPredefinedCategories
      .fold(0, (sum, p) => sum + p.seedLimitMinor(incomeMinor, currency));

  test('PKR: a ₨150,000 income seeds round rupee budgets under the income',
      () {
    const income = 15000000; // ₨150,000.00 in minor units

    expect(preset('Housing').seedLimitMinor(income, pkr), 3750000); // ₨37,500
    expect(preset('Food').seedLimitMinor(income, pkr), 2250000); // ₨22,500
    expect(preset('Transport').seedLimitMinor(income, pkr), 1500000); // ₨15,000

    expect(CurrencyUtils.formatAmount(3750000, pkr), '₨37,500.00');
    expect(seedTotal(income, pkr), lessThan(income));

    // Rounds DOWN to the nearest 100 major units, never up: 10% of
    // ₨123,456.78 is ₨12,345.678 → ₨12,300.
    expect(preset('Transport').seedLimitMinor(12345678, pkr), 1230000);
  });

  test('JPY: zero-decimal currency rounds in whole yen, not in sen', () {
    const income = 300000; // ¥300,000 — minor unit IS the yen

    expect(preset('Housing').seedLimitMinor(income, jpy), 75000); // ¥75,000
    expect(preset('Utilities').seedLimitMinor(income, jpy), 24000); // ¥24,000
    expect(CurrencyUtils.formatAmount(75000, jpy), '¥75,000');
    expect(seedTotal(income, jpy), lessThan(income));

    // 15% of ¥333,333 is ¥49,999.95 → floored to ¥49,999 → step 100 → ¥49,900.
    expect(preset('Food').seedLimitMinor(333333, jpy), 49900);

    // A share below one major unit stays proportional and never lands on 0 —
    // a 0 limit is read as "no budget" by the bars and the over-budget flag.
    expect(preset('Health').seedLimitMinor(10, jpy), greaterThan(0));
  });

  test('no income falls back to the presets, never to zero limits', () {
    for (final p in kPredefinedCategories) {
      expect(p.seedLimitMinor(0, usd),
          CurrencyUtils.fromMajor(p.defaultBudgetMajor, usd),
          reason: '${p.name} with no income');
      expect(p.seedLimitMinor(-1, jpy),
          CurrencyUtils.fromMajor(p.defaultBudgetMajor, jpy));
      expect(p.seedLimitMinor(0, usd), greaterThan(0), reason: p.name);
    }
    // Food: 500 major units → 50000 cents, 500 yen.
    expect(preset('Food').seedLimitMinor(0, usd), 50000);
    expect(preset('Food').seedLimitMinor(0, jpy), 500);

    // "Other" claims no share and carries no limit by design.
    expect(kOtherCategory.seedLimitMinor(15000000, pkr), 0);
  });
}
