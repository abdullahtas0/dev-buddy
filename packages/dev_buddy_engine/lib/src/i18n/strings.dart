// packages/dev_buddy/lib/src/i18n/strings.dart
import 'strings_en.dart';
import 'strings_tr.dart';

/// Abstract string provider for DevBuddy UI text.
///
/// Lightweight i18n without the `intl` package. Use [fromLocale] factory
/// to get the correct implementation based on a locale string.
///
/// Currently supports: English ('en') and Turkish ('tr').
abstract class DevBuddyStrings {
  const DevBuddyStrings();

  /// Returns the appropriate [DevBuddyStrings] implementation for [locale].
  ///
  /// Falls back to English for unsupported or null locales.
  factory DevBuddyStrings.fromLocale(String? locale) {
    return switch (locale) {
      'tr' => const StringsTr(),
      _ => const StringsEn(),
    };
  }

  // Panel
  String get panelTitle;
  String get clearAll;
  String get export;
  String get noEvents;

  // Tabs
  String get performanceTab;
  String get errorsTab;
  String get networkTab;
  String get memoryTab;
  String get rebuildsTab;

  // Metrics
  String get fps;
  String get memoryUsage;

  // Error helpers
  String get howToFix;
  String get unknownError;
  String get searchOnline;
  String get checkStackTrace;

  // Module empty states
  String get noPerformanceIssues;
  String get noErrorsCaught;
  String get noNetworkRequests;
  String get noMemoryIssues;
  String get noRebuildData;

  // Rebuild tracker
  String get topRebuilders;
}
