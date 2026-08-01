import 'package:flutter/material.dart';
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

  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isLarge = false,
    this.onTap,
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
              Text(label, style: AppFonts.labelMedium.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            amount,
            style: isLarge
                ? AppFonts.h3.copyWith(color: onSurface)
                : AppFonts.h5.copyWith(color: onSurface),
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
