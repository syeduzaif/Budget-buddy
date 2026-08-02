import 'package:flutter/material.dart' show IconData, Icons;

/// Centralized app constants — single source of truth for version and branding.
class AppConstants {
  AppConstants._();

  static const String appName = 'BuddgetBuddy';

  /// Kept in lockstep with `pubspec.yaml`'s `version:` — this string is what
  /// Settings and the splash screen show, and nothing derives it from the
  /// pubspec at runtime. Reset to 1.0.0 for the first real release (PRD D1):
  /// the inherited 1.1.0+3 counted CI builds of an unreleased app and would
  /// have shipped a "second-version" claim to a first-time user.
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Smart Budgeting, Simply Done';
}

// --- The reserved category ---------------------------------------------------
//
// One system bucket, not two: the old auto-created "Other" and the proposed
// "Uncategorised" meant the same thing, so they were merged at the 2026-08-02
// freeze (FD-2). "Other" is now an ordinary name any user may create.

/// The one reserved category name. Every month can hold one bucket under this
/// name; it is created on demand, carries no budget, and is never cloned
/// forward by the month rollover.
///
/// It exists so a transaction always has a row to appear in — an amount that
/// counts in a month's total but belongs to no visible row is the F-01 defect
/// (INV-1: the parts must sum to the whole).
const String kUncategorisedCategoryName = 'Uncategorised';

/// True for the reserved name, compared the way the attribution resolver
/// compares every other name: trimmed and case-insensitive. Renaming into or
/// out of it is refused in `CategoryRepository`.
bool isReservedCategoryName(String name) =>
    name.trim().toLowerCase() == kUncategorisedCategoryName.toLowerCase();

/// The reserved bucket's colour, as a LITERAL rather than a theme token.
///
/// This int is written into every bucket record, so it must not move when a
/// token is retuned — a stored colour that drifts with the theme repaints
/// history. Deliberately the neutral grey of the muted-text family (danish).
const int kUncategorisedColorValue = 0xFF9A9182;

/// The reserved bucket's glyph. Kept as an `Icons.*` constant so
/// `--tree-shake-icons` can still see it (an `IconData` built from a runtime
/// int is invisible to the tree-shaker), and mirrored by an explicit entry in
/// `AppIcons` — that map is derived from the pickable palette, which this icon
/// is deliberately NOT part of, so without the entry every bucket row would
/// render as a grey dot.
const IconData kUncategorisedIcon = Icons.label_off_outlined;
