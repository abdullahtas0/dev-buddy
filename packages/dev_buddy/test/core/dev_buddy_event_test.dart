// packages/dev_buddy/test/core/dev_buddy_event_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/core/dev_buddy_event.dart';
import 'package:dev_buddy/src/core/severity.dart';

void main() {
  group('DevBuddyEvent', () {
    test('creates event with all required fields', () {
      final event = DevBuddyEvent(
        module: 'performance',
        severity: Severity.warning,
        title: 'UI Jank Detected',
        description: 'Frame took 32ms to render',
        suggestions: ['Use ListView.builder', 'Reduce BoxShadow usage'],
        timestamp: DateTime(2026, 3, 26, 12, 0),
      );

      expect(event.module, equals('performance'));
      expect(event.severity, equals(Severity.warning));
      expect(event.title, equals('UI Jank Detected'));
      expect(event.description, equals('Frame took 32ms to render'));
      expect(event.suggestions, hasLength(2));
      expect(event.timestamp, equals(DateTime(2026, 3, 26, 12, 0)));
    });

    test('toJson serializes all fields', () {
      final event = DevBuddyEvent(
        module: 'error',
        severity: Severity.critical,
        title: 'Overflow',
        description: 'Bottom overflow by 24px',
        suggestions: ['Wrap with Expanded'],
        timestamp: DateTime(2026, 3, 26),
      );

      final json = event.toJson();
      expect(json['module'], equals('error'));
      expect(json['severity'], equals('critical'));
      expect(json['title'], equals('Overflow'));
      expect(json['suggestions'], contains('Wrap with Expanded'));
    });

    test('copyWith creates new instance with changed fields', () {
      final original = DevBuddyEvent(
        module: 'network',
        severity: Severity.info,
        title: 'Request OK',
        description: '200 in 150ms',
        suggestions: [],
      );

      final modified = original.copyWith(severity: Severity.warning);
      expect(modified.severity, equals(Severity.warning));
      expect(modified.module, equals('network')); // unchanged
      expect(identical(original, modified), isFalse);
    });
  });
}
