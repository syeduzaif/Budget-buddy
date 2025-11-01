import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/currency_helper.dart';

/// Custom progress bar widget that shows spending progress with color coding
class ProgressBar extends StatelessWidget {
  final double spent;
  final double limit;
  final double height;

  const ProgressBar({
    super.key,
    required this.spent,
    required this.limit,
    this.height = AppConstants.progressBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = limit > 0 ? (spent / limit) * 100.0 : 0.0;
    final colorValue = Helpers.getColorForPercentage(percentage);
    final progressColor = Color(colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
          child: SizedBox(
            height: height,
            child: LinearProgressIndicator(
              value: percentage > 100 ? 1.0 : (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: height,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingXS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${CurrencyHelper.formatAmount(spent, compact: true)} / ${CurrencyHelper.formatAmount(limit, compact: true)}',
              style: AppConstants.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppConstants.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

