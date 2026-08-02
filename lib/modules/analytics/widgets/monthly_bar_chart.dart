import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../utils/currency_utils.dart';
import '../../../utils/date_utils.dart';
import '../analytics_controller.dart';

class MonthlyBarChart extends StatelessWidget {
  /// Oldest→newest. Amounts are minor units; they are converted to major units
  /// once, here, because fl_chart takes doubles.
  final List<MonthlyTotal> data;
  final Currency currency;

  const MonthlyBarChart({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    // fl_chart's `getTitlesWidget` is a bare closure — it is handed a value and
    // a meta, never a BuildContext — so the resolved colour is captured HERE,
    // in build, where a context exists. Reaching for a raw token inside the
    // closure is how axis labels end up light-theme-coloured in the dark.
    final mutedColor = context.semanticColors.textMuted;

    if (data.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text('No data',
              style: AppFonts.bodySmall.copyWith(color: mutedColor)),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final maxMinor = data.fold(0, (m, e) => e.totalMinor > m ? e.totalMinor : m);
    final maxY = CurrencyUtils.toMajor(maxMinor, currency);
    final safeMax = maxY > 0 ? maxY * 1.2 : 100.0;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: safeMax,
          // EXPLICITLY disabled, and that word is load-bearing twice over.
          //
          // Omitting the argument does not mean "no touch": `BarTouchData()`
          // defaults to enabled, `BarChart._getData` then installs its built-in
          // callback, and a non-null callback is exactly what makes
          // `RenderBaseChart.handleEvent` hand the pointer to a
          // PanGestureRecognizer — which then wins the arena against the page's
          // scroll view, so a vertical drag starting inside the chart moved
          // nothing (F-10.1). Disabling it is the arena yield; the labels below
          // are what keep the information the tooltip used to carry.
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            // UI-18, second half: a 3-tick y-axis through
            // `formatAmountCompact` was built and MEASURED, then dropped. At
            // `reservedSize: 44` on a ~296dp-wide card every non-zero tick
            // clipped — the labels needed 1.8×–3× the width they had (worst
            // realistic cases: "₨750,000", "₫14,400,000"), and reserving
            // enough would have cost ~20% of the plot for three numbers the
            // tooltip already gives exactly. The empty tracks below carry the
            // "this month is zero, not broken" signal on their own. Revisit
            // with an abbreviated money format (k/M), which is a CurrencyUtils
            // decision, not a chart one.
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // The value, above its own rod. With touch off there is no tooltip
            // left to ask, and a bar chart whose bars have no numbers only says
            // "bigger than that one" (AC-10.1b).
            //
            // Formatted from the exact minor-unit total through the shared
            // compact formatter, never from the rod's geometry. `FittedBox`
            // shrinks a long amount rather than clipping or wrapping it; the
            // 48dp slot is the group width at the six-bar range on a ~300dp
            // card, which is the widest this chart gets. At six bars the labels
            // are legible but small — the real fix is an abbreviated k/M money
            // format (MF-1), which is a CurrencyUtils decision, not a chart one,
            // and is deliberately NOT smuggled in here.
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return SizedBox(
                    width: 48,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyUtils.formatAmountCompact(
                            data[i].totalMinor, currency),
                        // labelSmall carries no colour since F-11, and this one
                        // renders on a card in both themes.
                        style: AppFonts.labelSmall.copyWith(color: mutedColor),
                        maxLines: 1,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      AppDateUtils.formatMonthShort(data[i].month),
                      style: AppFonts.labelSmall.copyWith(color: mutedColor),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: CurrencyUtils.toMajor(data[i].totalMinor, currency),
                  // From the scheme: the raw token is the light-theme olive,
                  // which in dark mode sat on a dark card (UI-23).
                  color: colorScheme.primary,
                  width: 20,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusS),
                  // A month with no spending gets an empty track instead of
                  // nothing at all, so a sparse chart reads as empty rather
                  // than broken (UI-18).
                  // surfaceContainerHighest was #332D23 in dark — the card
                  // fill's exact hex, so the track was invisible by
                  // construction at 1.00:1 (N5). A translucent onSurface
                  // reads on both themes.
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: safeMax,
                    color: colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
