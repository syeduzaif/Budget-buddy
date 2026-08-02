import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/animations/animations.dart';
import '../../routes/app_routes.dart';
import '../../utils/currency_utils.dart';
import '../home/home_controller.dart';
import '../transaction_form/transaction_form_sheet.dart';
import 'dashboard_controller.dart';
import 'widgets/summary_card.dart';
import 'widgets/category_budget_list.dart';
import 'widgets/month_switcher.dart';
import 'widgets/recent_transactions_card.dart';
import 'widgets/spending_donut_chart.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          // Browsing forward CREATES data: goToNextMonth clones every category
          // into the month it lands on. Stop at the real current month — the
          // date picker already refuses future dates, so a future month could
          // only ever hold cloned categories and no transactions (UI-06).
          final atCurrentMonth = ctrl.isViewingCurrentMonth;
          return MonthSwitcher(
            monthKey: ctrl.settings.currentMonth.value,
            onPrevious: ctrl.goToPreviousMonth,
            // Null is the disabled state; MonthSwitcher owns what disabled
            // looks like on a dark app bar, which the M3 default got wrong.
            onNext: atCurrentMonth ? null : ctrl.goToNextMonth,
          );
        }),
        centerTitle: true,
        actions: [
          IconButton(
            // A person glyph promised a profile in an app with no accounts,
            // and the button announced itself as an unlabelled "button"
            // (UI-11).
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.settings_outlined,
                  size: 18, color: AppColors.primaryDark),
            ),
            tooltip: 'Settings',
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        // The summary cards' accent drives their label text, so the raw tokens
        // were light-theme colours on a dark card: primary 3.10:1, success
        // 4.25:1, error 3.22:1 (N6/N8). The scheme's equivalents are identical
        // in light and readable in dark.
        final colorScheme = Theme.of(context).colorScheme;
        final currency = ctrl.settings.currency;
        final atCurrentMonth = ctrl.isViewingCurrentMonth;
        final viewedMonth = ctrl.settings.currentMonth.value;
        final spentMinorByCategory = {
          for (final cat in ctrl.categories)
            cat.id: ctrl.spentForCategoryMinor(cat.id)
        };
        // Read inside the Obx body, like the spend map: reading it only inside
        // a child's builder would leave the transaction list off this Obx's
        // dependency list, which is how the Categories tab once showed stale
        // spend (UI-02).
        final recent = ctrl.recentTransactions;

        // Every entrance to the list opens the month the user is looking at.
        void openMonthTransactions() => Get.toNamed(
              AppRoutes.transactions,
              arguments: {'month': viewedMonth},
            );

        return RefreshIndicator(
          onRefresh: () async {
            ctrl.categories.refresh();
            ctrl.transactions.refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Income card
                FadeSlideItem(
                  index: 0,
                  child: SummaryCard(
                    label: 'Monthly Income',
                    amount: CurrencyUtils.formatAmount(
                        ctrl.settings.monthlyIncomeMinor.value, currency),
                    icon: Icons.account_balance_wallet_outlined,
                    color: colorScheme.primary,
                    isLarge: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                // Spent + Remaining row
                FadeSlideItem(
                  index: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          label: 'Spent',
                          amount: CurrencyUtils.formatAmount(
                              ctrl.totalSpentMinor, currency),
                          icon: Icons.trending_up,
                          // int vs int — an exact comparison now.
                          color: ctrl.totalSpentMinor >
                                  ctrl.settings.monthlyIncomeMinor.value
                              ? colorScheme.error
                              : AppColors.warning,
                          // Scoped to the viewed month, because that is what
                          // this number counts — the all-time list it used to
                          // open contradicted the figure that was tapped
                          // (F-04). Remaining stays non-interactive: there is
                          // no list of "remaining" to open.
                          onTap: openMonthTransactions,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: SummaryCard(
                          // "Remaining" is a promise about a month that is
                          // still running. On a closed month the same number
                          // is just what went unspent — and it is measured
                          // against TODAY's income either way, which is the
                          // residual honesty problem per-month income solves
                          // later (G6). The card is not suppressed: the two-up
                          // Row is fixed, and a month that renders one card
                          // instead of two reads as data loss.
                          label: atCurrentMonth ? 'Remaining' : 'Unspent',
                          amount: CurrencyUtils.formatAmount(
                              ctrl.remainingMinor, currency),
                          icon: Icons.savings_outlined,
                          color: ctrl.remainingMinor >= 0
                              ? colorScheme.tertiary
                              : colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // Recent transactions — absent entirely on a month with none.
                // No empty shell and no skeleton: the donut's empty state below
                // already carries that message once (F-04 AC-3).
                if (recent.isNotEmpty) ...[
                  FadeSlideItem(
                    index: 2,
                    child: RecentTransactionsCard(
                      transactions: recent,
                      categories: ctrl.categories,
                      currency: currency,
                      onSeeAll: openMonthTransactions,
                      onTapTransaction: (t) =>
                          openTransactionSheet(context, editing: t),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],

                // Spending donut chart
                if (ctrl.categories.isNotEmpty) ...[
                  FadeSlideItem(
                    // Indices are a stagger delay, nothing more, so the gap a
                    // missing section leaves is harmless — they are NOT
                    // renumbered at runtime.
                    index: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spending Breakdown', style: AppFonts.h6),
                        const SizedBox(height: AppSpacing.s),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            child: SpendingDonutChart(
                              categories: ctrl.categories,
                              spentMinorByCategory: spentMinorByCategory,
                              currency: currency,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],

                // Category budget list
                FadeSlideItem(
                  index: 4,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: CategoryBudgetList(
                        categories: ctrl.categories,
                        spentMinorByCategory: spentMinorByCategory,
                        currency: currency,
                        monthKey: viewedMonth,
                        isCurrentMonth: atCurrentMonth,
                        // The Categories tab, not the New Category form
                        // (UI-05).
                        onSeeAll: ctrl.categories.length > 4
                            ? () => Get.find<HomeController>().changeTab(1)
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
