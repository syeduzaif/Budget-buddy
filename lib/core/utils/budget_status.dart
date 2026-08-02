import 'package:flutter/material.dart';
import '../../utils/currency_utils.dart';
import '../constants/app_constants.dart';
import '../theme/app_semantic_colors.dart';

/// Where a category stands against its budget.
///
/// The only signal this app used to give arrived AFTER the overspend, and it
/// arrived twice in two shapes: `spent > limit && limit > 0` written out by
/// hand on the dashboard preview and again on the category card, with
/// different colours and different words either side. F-09 adds an earlier
/// rung to that ladder and a state for "no limit at all", which makes four —
/// too many to keep writing twice.
///
/// So the states, the captions and the colours are decided once, here, and
/// both surfaces render the answer. The only thing they still choose for
/// themselves is the money formatter: the preview is a four-row summary and
/// uses the compact one, the cards have the width for exact amounts.
enum BudgetState {
  /// Under the warning threshold. Renders exactly as it always did — a normal
  /// row must gain no height and no colour from this feature.
  normal,

  /// [kBudgetWarningRatio] of the limit or more, up to and including 100%.
  warning,

  /// Past the limit. The predicate is byte-for-byte the one that shipped.
  over,

  /// No budget was ever set. Not "0 spent of 0" — a full-width empty rail
  /// reads as a full bar, so this state draws no bar at all.
  noLimit,
}

@immutable
class BudgetStatus {
  final BudgetState state;
  final int spentMinor;
  final int limitMinor;

  const BudgetStatus._(this.state, this.spentMinor, this.limitMinor);

  factory BudgetStatus.of({required int spentMinor, required int limitMinor}) {
    if (limitMinor <= 0) {
      return BudgetStatus._(BudgetState.noLimit, spentMinor, limitMinor);
    }
    // Kept in this order and this form on purpose: `spent > limit` is the
    // shipped over-predicate, so exactly-at-the-limit falls through to warning
    // rather than changing meaning under the rewrite.
    if (spentMinor > limitMinor) {
      return BudgetStatus._(BudgetState.over, spentMinor, limitMinor);
    }
    if (spentMinor / limitMinor >= kBudgetWarningRatio) {
      return BudgetStatus._(BudgetState.warning, spentMinor, limitMinor);
    }
    return BudgetStatus._(BudgetState.normal, spentMinor, limitMinor);
  }

  /// `spent / limit`, 0 when there is no limit. `int / int` is a `double` in
  /// Dart, so this is a ratio and not money — the minor units never leave
  /// integer arithmetic.
  double get ratio => limitMinor > 0 ? spentMinor / limitMinor : 0.0;

  /// What the progress bar should read, clamped so an overspend fills it once
  /// rather than overflowing.
  double get barValue => ratio.clamp(0.0, 1.0);

  /// False only for [BudgetState.noLimit]: zero of zero is not "full".
  bool get showsBar => state != BudgetState.noLimit;

  bool get showsOverIcon => state == BudgetState.over;

  /// The words under the bar, or null for a normal row.
  ///
  /// Every non-normal state carries text, so no state in this ladder is
  /// distinguishable by colour alone. [compact] picks the formatter: whole
  /// major units for the dashboard preview, exact amounts on the cards.
  String? caption(Currency currency, {required bool compact}) {
    String money(int minorUnits) => compact
        ? CurrencyUtils.formatAmountCompact(minorUnits, currency)
        : CurrencyUtils.formatAmount(minorUnits, currency);

    switch (state) {
      case BudgetState.normal:
        return null;
      case BudgetState.warning:
        // At exactly 100% this is "…0 left", which is the true statement.
        return '${money(limitMinor - spentMinor)} left';
      case BudgetState.over:
        // No exclamation mark: the number is the alarming part (D4).
        return 'Over by ${money(spentMinor - limitMinor)}';
      case BudgetState.noLimit:
        return 'No limit set';
    }
  }

  /// Colour for the amount text, or null to leave the surface's default.
  Color? amountColor(BuildContext context) {
    switch (state) {
      case BudgetState.warning:
        return context.semanticColors.warning;
      case BudgetState.over:
        return Theme.of(context).colorScheme.error;
      case BudgetState.normal:
      case BudgetState.noLimit:
        return null;
    }
  }

  /// Colour for [caption]. Muted for "no limit" — it is a statement of fact,
  /// not a warning.
  Color captionColor(BuildContext context) {
    switch (state) {
      case BudgetState.warning:
        return context.semanticColors.warning;
      case BudgetState.over:
        return Theme.of(context).colorScheme.error;
      case BudgetState.normal:
      case BudgetState.noLimit:
        return context.semanticColors.textMuted;
    }
  }

  /// Bar fill. The category's own colour until the budget starts to matter,
  /// then the state's.
  Color barColor(BuildContext context, Color categoryColor) {
    switch (state) {
      case BudgetState.warning:
        return context.semanticColors.warning;
      case BudgetState.over:
        return Theme.of(context).colorScheme.error;
      case BudgetState.normal:
      case BudgetState.noLimit:
        return categoryColor;
    }
  }
}
