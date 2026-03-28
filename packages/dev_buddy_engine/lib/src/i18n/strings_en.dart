// packages/dev_buddy/lib/src/i18n/strings_en.dart
import 'strings.dart';

/// English string implementation for DevBuddy UI.
class StringsEn extends DevBuddyStrings {
  const StringsEn();

  // Panel
  @override
  String get panelTitle => 'DevBuddy';
  @override
  String get clearAll => 'Clear All';
  @override
  String get export => 'Export';
  @override
  String get noEvents => 'No events recorded yet.';

  // Tabs
  @override
  String get performanceTab => 'Performance';
  @override
  String get errorsTab => 'Errors';
  @override
  String get networkTab => 'Network';
  @override
  String get memoryTab => 'Memory';
  @override
  String get rebuildsTab => 'Rebuilds';

  // Metrics
  @override
  String get fps => 'FPS';
  @override
  String get memoryUsage => 'Memory Usage';

  // Error helpers
  @override
  String get howToFix => 'How to fix';
  @override
  String get unknownError => 'Unknown error';
  @override
  String get searchOnline => 'Search online';
  @override
  String get checkStackTrace => 'Check stack trace';

  // Module empty states
  @override
  String get noPerformanceIssues => 'No performance issues detected';
  @override
  String get noErrorsCaught => 'No errors caught';
  @override
  String get noNetworkRequests => 'No network requests captured';
  @override
  String get noMemoryIssues => 'No memory issues detected';
  @override
  String get noRebuildData => 'No rebuild data yet';

  // Rebuild tracker
  @override
  String get topRebuilders => 'Top Rebuilders';
}
