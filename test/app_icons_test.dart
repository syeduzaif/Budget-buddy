import 'package:budget_buddy/core/utils/app_icons.dart';
import 'package:budget_buddy/data/predefined_categories.dart';
import 'package:budget_buddy/modules/category_form/category_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// UI-03 regression guard: the code-point map used to be hand-written hex and
/// had drifted from the Material constants, so 7 of the 9 seeded categories
/// rendered a plain dot instead of their glyph — on the cards, in the dashboard
/// rows and in the add-sheet picker.
void main() {
  test('every seeded category resolves to a real glyph, not the dot fallback',
      () {
    for (final preset in kPredefinedCategories) {
      expect(AppIcons.fromCodePoint(preset.iconCodePoint), isNot(Icons.circle),
          reason: '${preset.name} falls back to the dot');
      expect(AppIcons.fromCodePoint(preset.iconCodePoint).codePoint,
          preset.iconCodePoint);
    }
    // The fallback still exists for a null or unknown code point.
    expect(AppIcons.fromCodePoint(null), Icons.circle);
    expect(AppIcons.fromCodePoint(0x1), Icons.circle);
    // And the whole picker palette resolves, not just the seeds.
    for (final icon in CategoryFormController.iconPalette) {
      expect(AppIcons.fromCodePoint(icon.codePoint), icon);
    }
  });
}
