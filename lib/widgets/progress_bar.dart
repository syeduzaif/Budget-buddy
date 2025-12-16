import 'package:flutter/material.dart';
import '../utils/helpers.dart';

/// Custom progress bar widget that shows spending progress with color coding
class ProgressBar extends StatelessWidget {
  final double spent;
  final double limit;

  const ProgressBar({
    super.key,
    required this.spent,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = limit > 0 ? (spent / limit) * 100.0 : 0.0;
    final colorValue = Helpers.getColorForPercentage(percentage);
    final progressColor = Color(colorValue);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 10,
        child: LinearProgressIndicator(
          value: percentage > 100 ? 1.0 : (percentage / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          minHeight: 10,
        ),
      ),
    );
  }
}
