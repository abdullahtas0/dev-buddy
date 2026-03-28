// packages/dev_buddy/test/modules/memory/leak_heuristic_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/modules/memory/leak_heuristic.dart';
import 'package:dev_buddy/src/modules/memory/memory_sampler.dart';
import 'package:dev_buddy/src/core/severity.dart';

void main() {
  group('LeakHeuristic', () {
    late LeakHeuristic heuristic;

    setUp(() {
      heuristic = const LeakHeuristic(warningThresholdMb: 150);
    });

    test('returns null for healthy memory', () {
      final sampler = MemorySampler(maxSamples: 5);
      sampler.addSample(80);
      sampler.addSample(85);
      sampler.addSample(82);
      final result = heuristic.evaluate(sampler);
      expect(result, isNull);
    });

    test('warns when threshold exceeded', () {
      final sampler = MemorySampler(maxSamples: 5);
      sampler.addSample(160);
      final result = heuristic.evaluate(sampler);
      expect(result, isNotNull);
      expect(result!.severity, equals(Severity.warning));
    });

    test('critical when monotonic growth above threshold', () {
      final sampler = MemorySampler(maxSamples: 5);
      sampler.addSample(120);
      sampler.addSample(140);
      sampler.addSample(160);
      sampler.addSample(180);
      sampler.addSample(200);
      final result = heuristic.evaluate(sampler);
      expect(result, isNotNull);
      expect(result!.severity, equals(Severity.critical));
      expect(result.suggestions.any((s) => s.contains('dispose')), isTrue);
    });

    test('suggestions mention controllers and image cache', () {
      final sampler = MemorySampler(maxSamples: 5);
      sampler.addSample(200);
      final result = heuristic.evaluate(sampler);
      expect(result, isNotNull);
      expect(
        result!.suggestions.any((s) =>
            s.contains('Controller') || s.contains('dispose')),
        isTrue,
      );
    });
  });
}
