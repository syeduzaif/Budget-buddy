import 'package:flutter/material.dart';
import '../../modules/category_form/category_form_controller.dart';

/// Resolves a stored `iconCodePoint` back to the icon the user picked.
///
/// The map is DERIVED from the one icon palette the app offers
/// ([CategoryFormController.iconPalette]) rather than hand-written: the old
/// hardcoded hex keys had drifted from the Material constants, so 7 of the 9
/// seed categories fell through to [Icons.circle] everywhere they were drawn
/// (UI-03). Derived, the two lists cannot disagree.
///
/// The values stay `Icons.*` CONSTANTS. That is what keeps
/// `--tree-shake-icons` working — an `IconData` built from a runtime int is
/// invisible to the tree-shaker, which then either strips the glyph (blank
/// boxes in release) or forces the whole font to ship.
///
/// NOTE: `core` importing a module controller is the wrong direction. The
/// palette is here-and-only-here today, so deriving beats duplicating; the
/// clean fix is to move `iconPalette` down into `core` or `data` and have the
/// form read it from there. Flagged, not smuggled.
class AppIcons {
  AppIcons._();

  static final Map<int, IconData> _iconMap = {
    for (final icon in CategoryFormController.iconPalette)
      icon.codePoint: icon,
  };

  /// The [IconData] for a stored [codePoint], or [Icons.circle] for a null or
  /// unknown one — a category saved by a future build with a wider palette must
  /// degrade to a dot, never crash.
  static IconData fromCodePoint(int? codePoint) {
    if (codePoint == null) return Icons.circle;
    return _iconMap[codePoint] ?? Icons.circle;
  }
}
