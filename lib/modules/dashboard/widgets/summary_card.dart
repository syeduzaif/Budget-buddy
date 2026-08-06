import 'package:flutter/material.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isLarge;

  /// Optional destination. Cards without one stay visibly inert — no ink
  /// splash, no ripple — so a card that looks tappable always is (UI-19).
  final VoidCallback? onTap;

  /// What a screen reader says instead of reading [amount] literally.
  ///
  /// Exists for one case (D-010): when income is unknown the Remaining card
  /// shows an em dash, and "Remaining, —" is either silence or the word "dash"
  /// depending on the reader. Null everywhere else, which leaves the amount to
  /// be announced exactly as it is written.
  final String? amountSemanticsLabel;

  /// Overrides the amount's colour. Null keeps the default `onSurface`.
  ///
  /// Additive and defaulted for the same D-010 case: the withheld figure is
  /// muted, and [color] cannot carry it — that one paints the icon and the
  /// label, not the number. Kept as a colour rather than a "withheld" flag so
  /// this shared component stays ignorant of income.
  final Color? amountColor;

  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isLarge = false,
    this.onTap,
    this.amountSemanticsLabel,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final content = Padding(
      padding: EdgeInsets.all(isLarge ? AppSpacing.l : AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: AppSpacing.iconS),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(label,
                    style: AppFonts.labelMedium.copyWith(color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              // A summary card has no conventional "I open something" shape the
              // way a list row does, so the one that does open something says so
              // (F-04 AC-5). Muted, not the card's accent: this is a
              // navigational hint, not part of the money signal.
              if (onTap != null)
                Icon(Icons.chevron_right,
                    size: AppSpacing.iconS,
                    color: context.semanticColors.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            amount,
            semanticsLabel: amountSemanticsLabel,
            style: isLarge
                ? AppFonts.h3.copyWith(color: amountColor ?? onSurface)
                : AppFonts.h5.copyWith(color: amountColor ?? onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return Card(
      elevation: AppSpacing.elevationS,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
              child: content,
            ),
    );
  }
}
