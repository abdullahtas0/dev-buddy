// packages/dev_buddy/lib/src/ui/theme/dev_buddy_theme.dart
import 'package:flutter/material.dart';
import '../../core/severity.dart';

/// Internal theme constants for DevBuddy UI.
/// Apple-inspired: clean, minimal, generous spacing.
/// Supports both light and dark mode via [Brightness] parameter.
abstract final class DevBuddyTheme {
  static const double pillHeight = 32.0;
  static const double pillBorderRadius = 16.0;
  static const double panelBorderRadius = 20.0;
  static const double panelMaxHeight = 0.6; // 60% of screen

  static const EdgeInsets pillPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  static const TextStyle pillText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle eventTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle eventDescription = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: Color(0xFF666666),
  );

  static const TextStyle eventDescriptionDark = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: Color(0xFF9E9E9E),
  );

  static const TextStyle suggestionText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: Color(0xFF1E88E5),
  );

  static const TextStyle suggestionTextDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: Color(0xFF64B5F6),
  );

  static Color colorForSeverity(Severity severity) => switch (severity) {
    Severity.info => const Color(0xFF4CAF50), // Green
    Severity.warning => const Color(0xFFFFA726), // Orange
    Severity.critical => const Color(0xFFEF5350), // Red
  };

  // Light mode colors
  static const Color panelBackground = Color(0xFFF8F9FA);
  static const Color headerButtonBackground = Color(0xFFE8E8E8);
  static const Color headerButtonText = Color(0xFF666666);
  static const Color handleBarColor = Color(0xFFBDBDBD);
  static const Color emptyStateText = Color(0xFF9E9E9E);

  // Dark mode colors
  static const Color panelBackgroundDark = Color(0xFF1E1E1E);
  static const Color headerButtonBackgroundDark = Color(0xFF333333);
  static const Color headerButtonTextDark = Color(0xFFB0B0B0);
  static const Color handleBarColorDark = Color(0xFF555555);
  static const Color emptyStateTextDark = Color(0xFF757575);

  /// Returns the appropriate panel background for the given [brightness].
  static Color panelBackgroundFor(Brightness brightness) =>
      brightness == Brightness.dark ? panelBackgroundDark : panelBackground;

  /// Returns the appropriate header button background for the given [brightness].
  static Color headerButtonBackgroundFor(Brightness brightness) =>
      brightness == Brightness.dark
      ? headerButtonBackgroundDark
      : headerButtonBackground;

  /// Returns the appropriate header button text color for the given [brightness].
  static Color headerButtonTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? headerButtonTextDark : headerButtonText;

  /// Returns the appropriate description style for the given [brightness].
  static TextStyle eventDescriptionFor(Brightness brightness) =>
      brightness == Brightness.dark ? eventDescriptionDark : eventDescription;

  /// Returns the appropriate suggestion style for the given [brightness].
  static TextStyle suggestionTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? suggestionTextDark : suggestionText;

  static const BoxShadow pillShadow = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
}
