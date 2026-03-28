// packages/dev_buddy/lib/src/export/report_model.dart
import '../core/event.dart';

/// Immutable data model for a DevBuddy diagnostic report.
///
/// Contains a snapshot of all captured events plus optional device info.
/// Passed to [DevBuddyExporterImpl] for JSON or text serialization.
class DevBuddyReport {
  /// The diagnostic events captured during the session.
  final List<DevBuddyEvent> events;

  /// Timestamp when this report was generated.
  final DateTime generatedAt;

  /// Optional device/platform information for context.
  final Map<String, dynamic> deviceInfo;

  DevBuddyReport({
    required List<DevBuddyEvent> events,
    required this.generatedAt,
    Map<String, dynamic> deviceInfo = const {},
  }) : events = List.unmodifiable(events),
       deviceInfo = Map.unmodifiable(deviceInfo);
}
