// packages/dev_buddy/test/core/severity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/core/severity.dart';

void main() {
  group('Severity', () {
    test('has correct ordering: info < warning < critical', () {
      expect(Severity.info.index, lessThan(Severity.warning.index));
      expect(Severity.warning.index, lessThan(Severity.critical.index));
    });

    test('isAtLeast returns true for same or higher severity', () {
      expect(Severity.critical.isAtLeast(Severity.warning), isTrue);
      expect(Severity.warning.isAtLeast(Severity.warning), isTrue);
      expect(Severity.info.isAtLeast(Severity.warning), isFalse);
    });

    test('emoji returns correct icon for each severity', () {
      expect(Severity.info.emoji, equals('ℹ️'));
      expect(Severity.warning.emoji, equals('🟡'));
      expect(Severity.critical.emoji, equals('🔴'));
    });
  });
}
