// packages/dev_buddy/test/modules/performance/jank_detector_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/modules/performance/jank_detector.dart';
import 'package:dev_buddy/src/core/severity.dart';

void main() {
  group('JankDetector', () {
    late JankDetector detector;

    setUp(() {
      detector = const JankDetector(thresholdMs: 16.7);
    });

    test('single jank frame emits warning severity', () {
      final result = detector.evaluate(durationMs: 20.0, consecutiveJanks: 1);
      expect(result.severity, equals(Severity.warning));
    });

    test('consecutive janks escalate to critical', () {
      final result = detector.evaluate(durationMs: 40.0, consecutiveJanks: 5);
      expect(result.severity, equals(Severity.critical));
    });

    test('provides human-readable suggestions', () {
      final result = detector.evaluate(durationMs: 32.0, consecutiveJanks: 1);
      expect(result.suggestions, isNotEmpty);
      expect(
        result.suggestions.any((s) => s.contains('ListView.builder')),
        isTrue,
      );
    });

    test('severe jank (>50ms) mentions build method', () {
      final result = detector.evaluate(durationMs: 55.0, consecutiveJanks: 1);
      expect(
        result.suggestions.any((s) => s.toLowerCase().contains('build')),
        isTrue,
      );
    });
  });
}
