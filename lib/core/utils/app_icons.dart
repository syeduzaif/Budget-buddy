import 'package:flutter/material.dart';

class AppIcons {
  static const Map<int, IconData> _iconMap = {
    // Material Icons
    0xe532: Icons.restaurant,
    0xe1d1: Icons.directions_car,
    0xe318: Icons.home,
    0xebc6: Icons.bolt,
    0xe405: Icons.movie,
    0xe8cc: Icons.shopping_bag,
    0xe3f3: Icons.local_hospital,
    0xe80c: Icons.school,
    0xef6a: Icons.savings,
    0xe195: Icons.flight,
    0xe91d: Icons.pets,
    0xe317: Icons.checkroom,
    0xe511: Icons.phone_android,
    0xe245: Icons.fitness_center,
    0xefe0: Icons.coffee,
    0xe150: Icons.child_care,
    0xe160: Icons.card_giftcard,
    0xe869: Icons.build,
    0xe63e: Icons.wifi,
    0xe3fa: Icons.more_horiz,
    0xe14c: Icons.circle,
    0xe892: Icons.label_outline,
    0xe227: Icons.attach_money,
    0xe872: Icons.delete_outline,
    0xe5ca: Icons.check,
  };

  /// Returns the [IconData] for a given [codePoint].
  /// Defaults to [Icons.circle] if not found.
  static IconData fromCodePoint(int? codePoint) {
    if (codePoint == null) return Icons.circle;
    return _iconMap[codePoint] ?? Icons.circle;
  }
}
