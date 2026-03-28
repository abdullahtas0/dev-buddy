// packages/dev_buddy/lib/src/export/report_exporter.dart
import 'report_model.dart';

/// Exports a [DevBuddyReport] as JSON or human-readable text.
///
/// This is the real implementation that replaces the noop stub
/// in `_conditional/dev_buddy_noop.dart`.
class DevBuddyExporterImpl {
  final DevBuddyReport report;

  const DevBuddyExporterImpl({required this.report});

  /// Serializes the report to a JSON-compatible [Map].
  ///
  /// The returned map can be passed to `jsonEncode()` directly.
  Map<String, dynamic> exportJson() {
    return {
      'generatedAt': report.generatedAt.toIso8601String(),
      'deviceInfo': Map<String, dynamic>.from(report.deviceInfo),
      'events': [
        for (final event in report.events) event.toJson(),
      ],
    };
  }

  /// Serializes the report to a human-readable text format.
  ///
  /// Suitable for sharing in bug reports, Slack messages, or log files.
  String exportText() {
    final buffer = StringBuffer();

    buffer.writeln('=== DevBuddy Report ===');
    buffer.writeln('Generated: ${report.generatedAt.toIso8601String()}');

    if (report.deviceInfo.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('--- Device Info ---');
      for (final entry in report.deviceInfo.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    }

    buffer.writeln();

    if (report.events.isEmpty) {
      buffer.writeln('No events recorded.');
      return buffer.toString();
    }

    buffer.writeln('--- Events (${report.events.length}) ---');
    buffer.writeln();

    for (final (index, event) in report.events.indexed) {
      buffer.writeln('#${index + 1} [${event.severity.name.toUpperCase()}] '
          '${event.module} - ${event.title}');
      buffer.writeln('   ${event.description}');
      if (event.suggestions.isNotEmpty) {
        buffer.writeln('   Suggestions:');
        for (final suggestion in event.suggestions) {
          buffer.writeln('   - $suggestion');
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
