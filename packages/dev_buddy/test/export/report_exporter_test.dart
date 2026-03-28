// packages/dev_buddy/test/export/report_exporter_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/core/dev_buddy_event.dart';
import 'package:dev_buddy/src/core/severity.dart';
import 'package:dev_buddy/src/export/report_model.dart';
import 'package:dev_buddy/src/export/report_exporter.dart';

void main() {
  late DevBuddyExporterImpl exporter;
  late List<DevBuddyEvent> sampleEvents;
  final fixedTime = DateTime(2026, 3, 26, 12, 0, 0);

  setUp(() {
    sampleEvents = [
      DevBuddyEvent(
        module: 'performance',
        severity: Severity.warning,
        title: 'Jank detected',
        description: 'Frame took 32ms',
        suggestions: ['Reduce widget complexity'],
        timestamp: fixedTime,
        metadata: {'frameDuration': 32.0},
      ),
      DevBuddyEvent(
        module: 'network',
        severity: Severity.critical,
        title: 'Slow request',
        description: 'GET /api/users took 5s',
        suggestions: ['Add caching', 'Check server'],
        timestamp: fixedTime.add(const Duration(seconds: 1)),
      ),
    ];
  });

  group('DevBuddyExporterImpl', () {
    group('with events', () {
      setUp(() {
        final report = DevBuddyReport(
          events: sampleEvents,
          generatedAt: fixedTime,
          deviceInfo: const {'platform': 'android', 'version': '14'},
        );
        exporter = DevBuddyExporterImpl(report: report);
      });

      test('exportJson returns valid JSON map with events', () {
        final json = exporter.exportJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['generatedAt'], fixedTime.toIso8601String());
        expect(json['deviceInfo'], isA<Map<String, dynamic>>());
        expect(json['events'], isA<List>());
        expect((json['events'] as List).length, 2);

        // Verify it's valid JSON by encoding/decoding roundtrip
        final encoded = jsonEncode(json);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        expect(decoded['events'], hasLength(2));
      });

      test('exportJson events contain correct fields', () {
        final json = exporter.exportJson();
        final events = json['events'] as List;
        final first = events[0] as Map<String, dynamic>;

        expect(first['module'], 'performance');
        expect(first['severity'], 'warning');
        expect(first['title'], 'Jank detected');
        expect(first['description'], 'Frame took 32ms');
        expect(first['suggestions'], ['Reduce widget complexity']);
      });

      test('exportText returns human-readable text', () {
        final text = exporter.exportText();

        expect(text, contains('DevBuddy Report'));
        expect(text, contains('Jank detected'));
        expect(text, contains('Slow request'));
        expect(text, contains('performance'));
        expect(text, contains('network'));
        expect(text, contains('Reduce widget complexity'));
      });

      test('exportText includes device info', () {
        final text = exporter.exportText();

        expect(text, contains('android'));
      });
    });

    group('with empty events', () {
      setUp(() {
        final report = DevBuddyReport(events: const [], generatedAt: fixedTime);
        exporter = DevBuddyExporterImpl(report: report);
      });

      test('exportJson returns map with empty events list', () {
        final json = exporter.exportJson();

        expect(json['events'], isA<List>());
        expect((json['events'] as List), isEmpty);
        expect(json['generatedAt'], isNotNull);
      });

      test('exportText returns report with no-events indicator', () {
        final text = exporter.exportText();

        expect(text, contains('DevBuddy Report'));
        expect(text, contains('No events'));
      });
    });
  });

  group('DevBuddyReport', () {
    test('creates immutable report with required fields', () {
      final report = DevBuddyReport(
        events: sampleEvents,
        generatedAt: fixedTime,
      );

      expect(report.events, hasLength(2));
      expect(report.generatedAt, fixedTime);
      expect(report.deviceInfo, isEmpty);
    });

    test('creates report with optional device info', () {
      final report = DevBuddyReport(
        events: sampleEvents,
        generatedAt: fixedTime,
        deviceInfo: const {'platform': 'ios'},
      );

      expect(report.deviceInfo['platform'], 'ios');
    });

    test('events list is unmodifiable', () {
      final report = DevBuddyReport(
        events: sampleEvents,
        generatedAt: fixedTime,
      );

      expect(
        () => (report.events as List).add(sampleEvents.first),
        throwsUnsupportedError,
      );
    });
  });
}
