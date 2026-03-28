import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

void main() {
  group('AuditLogEntry', () {
    test('serializes to JSON line', () {
      final entry = AuditLogEntry(
        timestamp: DateTime(2026, 3, 28, 12, 0),
        type: 'event',
        data: {'module': 'performance', 'title': 'Jank'},
      );

      final line = entry.toJsonLine();
      expect(line, contains('"type":"event"'));
      expect(line, contains('"module":"performance"'));
    });

    test('round-trips through JSON line', () {
      final original = AuditLogEntry(
        timestamp: DateTime(2026, 3, 28, 12, 0),
        type: 'state',
        data: {'source': 'riverpod:counter', 'version': 5},
      );

      final line = original.toJsonLine();
      final restored = AuditLogEntry.fromJsonLine(line);

      expect(restored.type, 'state');
      expect(restored.data['source'], 'riverpod:counter');
      expect(restored.data['version'], 5);
    });

    test('creates from DevBuddyEvent', () {
      final event = DevBuddyEvent(
        module: 'performance',
        severity: Severity.warning,
        title: 'UI Jank',
        description: 'Frame drop',
        suggestions: ['fix'],
      );

      final entry = AuditLogEntry.fromEvent(event);
      expect(entry.type, 'event');
      expect(entry.data['module'], 'performance');
      expect(entry.data['severity'], 'warning');
    });

    test('creates from StateSnapshot', () {
      final snapshot = StateSnapshot(
        version: 3,
        timestamp: DateTime(2026, 3, 28),
        source: 'riverpod:counter',
        action: 'increment',
        serializedDiff: '{"count":[1,2]}',
      );

      final entry = AuditLogEntry.fromStateSnapshot(snapshot);
      expect(entry.type, 'state');
      expect(entry.data['source'], 'riverpod:counter');
      expect(entry.data['action'], 'increment');
    });
  });

  group('CrashReport', () {
    test('parses from JSON lines', () {
      final lines = [
        '{"t":"2026-03-28T12:00:00.000","type":"event","module":"perf","severity":"warning","title":"Jank"}',
        '{"t":"2026-03-28T12:00:01.000","type":"state","source":"counter","version":1}',
        '{"t":"2026-03-28T12:00:02.000","type":"error","module":"errors","severity":"critical","title":"Null check"}',
      ];

      final report = CrashReport.fromJsonLines(lines);
      expect(report.auditTrail, hasLength(3));
      expect(report.events, hasLength(2));
      expect(report.stateChanges, hasLength(1));
      expect(report.errors, hasLength(1));
    });

    test('skips corrupted lines gracefully', () {
      final lines = [
        '{"t":"2026-03-28T12:00:00.000","type":"event","module":"perf"}',
        'CORRUPTED LINE',
        '{"t":"2026-03-28T12:00:01.000","type":"state","source":"counter"}',
      ];

      final report = CrashReport.fromJsonLines(lines);
      expect(report.auditTrail, hasLength(2)); // corrupted line skipped
    });

    test('handles empty lines', () {
      final lines = [
        '',
        '   ',
        '{"t":"2026-03-28T12:00:00.000","type":"event","module":"test"}',
      ];
      final report = CrashReport.fromJsonLines(lines);
      expect(report.auditTrail, hasLength(1));
    });

    test('toJson serializes correctly', () {
      final report = CrashReport(
        auditTrail: [
          AuditLogEntry(
            timestamp: DateTime(2026, 3, 28),
            type: 'event',
            data: {'module': 'test'},
          ),
        ],
        crashTimestamp: DateTime(2026, 3, 28, 12, 0),
        deviceInfo: {'os': 'Android 14'},
      );

      final json = report.toJson();
      expect(json['event_count'], 1);
      expect(json['device_info']['os'], 'Android 14');
      expect(json['trail'], hasLength(1));
    });
  });
}
