import 'dart:convert';

import '../core/event.dart';
import '../core/state_store.dart';

/// A single entry in the crash-safe audit log.
///
/// Written continuously by the engine to an append-only `.jsonl` file.
/// On crash, the OS closes the file descriptor — no allocation needed.
/// On next launch, the file is parsed to reconstruct the crash context.
class AuditLogEntry {
  final DateTime timestamp;
  final String type; // 'event', 'state', 'network', 'error'
  final Map<String, dynamic> data;

  const AuditLogEntry({
    required this.timestamp,
    required this.type,
    required this.data,
  });

  /// Serialize to a single JSON line (for .jsonl format).
  /// Data is nested under 'd' key to prevent key collisions with 't' and 'type'.
  String toJsonLine() {
    return jsonEncode({
      't': timestamp.toIso8601String(),
      'type': type,
      'd': data,
    });
  }

  /// Parse from a single JSON line.
  factory AuditLogEntry.fromJsonLine(String line) {
    final json = jsonDecode(line) as Map<String, dynamic>;
    return AuditLogEntry(
      timestamp: DateTime.parse(json['t'] as String),
      type: json['type'] as String,
      data: json['d'] is Map<String, dynamic>
          ? json['d'] as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }

  /// Create from a DevBuddyEvent.
  factory AuditLogEntry.fromEvent(DevBuddyEvent event) => AuditLogEntry(
        timestamp: event.timestamp,
        type: event.module == 'errors' ? 'error' : 'event',
        data: {
          'module': event.module,
          'severity': event.severity.name,
          'title': event.title,
          if (event.metadata != null) 'metadata': event.metadata,
        },
      );

  /// Create from a StateSnapshot.
  factory AuditLogEntry.fromStateSnapshot(StateSnapshot snapshot) =>
      AuditLogEntry(
        timestamp: snapshot.timestamp,
        type: 'state',
        data: {
          'source': snapshot.source,
          'version': snapshot.version,
          if (snapshot.action != null) 'action': snapshot.action,
          if (snapshot.serializedDiff != null) 'diff': snapshot.serializedDiff,
        },
      );
}

/// Reconstructed crash context from an audit log file.
///
/// On next app launch, if an unclean shutdown is detected, the audit log
/// is parsed into this model for display in the DevBuddy UI.
class CrashReport {
  final List<AuditLogEntry> auditTrail;
  final DateTime? crashTimestamp;
  final Map<String, dynamic> deviceInfo;

  const CrashReport({
    required this.auditTrail,
    this.crashTimestamp,
    this.deviceInfo = const {},
  });

  /// Events from the audit trail.
  List<AuditLogEntry> get events =>
      auditTrail.where((e) => e.type == 'event' || e.type == 'error').toList();

  /// State snapshots from the audit trail.
  List<AuditLogEntry> get stateChanges =>
      auditTrail.where((e) => e.type == 'state').toList();

  /// Network events from the audit trail.
  List<AuditLogEntry> get networkEvents =>
      auditTrail.where((e) => e.type == 'network').toList();

  /// Error events from the audit trail.
  List<AuditLogEntry> get errors =>
      auditTrail.where((e) => e.type == 'error').toList();

  Map<String, dynamic> toJson() => {
        'crash_timestamp': crashTimestamp?.toIso8601String(),
        'device_info': deviceInfo,
        'event_count': events.length,
        'state_change_count': stateChanges.length,
        'error_count': errors.length,
        'trail': auditTrail.map((e) => jsonDecode(e.toJsonLine())).toList(),
      };

  /// Parse a crash report from a list of JSON lines (the .jsonl file content).
  factory CrashReport.fromJsonLines(List<String> lines, {
    DateTime? crashTimestamp,
    Map<String, dynamic> deviceInfo = const {},
  }) {
    final entries = <AuditLogEntry>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        entries.add(AuditLogEntry.fromJsonLine(line));
      } catch (_) {
        // Skip corrupted lines (crash may have truncated the last line)
      }
    }
    return CrashReport(
      auditTrail: entries,
      crashTimestamp: crashTimestamp,
      deviceInfo: deviceInfo,
    );
  }
}
