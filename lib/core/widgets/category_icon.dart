import 'package:flutter/material.dart';
import '../../data/models/category.dart';

class CategoryIcon extends StatelessWidget {
  final Category category;
  final double size;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    if (category.iconCodePoint == null) {
      return Container(
        width: size * 0.5,
        height: size * 0.5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        category.icon,
        size: size * 0.6,
        color: color,
      ),
    );
  }
}
