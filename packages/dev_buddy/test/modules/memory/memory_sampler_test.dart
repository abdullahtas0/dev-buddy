// packages/dev_buddy/test/modules/memory/memory_sampler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/modules/memory/memory_sampler.dart';

void main() {
  group('MemorySampler', () {
    late MemorySampler sampler;

    setUp(() {
      sampler = MemorySampler(maxSamples: 5);
    });

    test('records memory samples', () {
      sampler.addSample(100);
      sampler.addSample(110);
      expect(sampler.samples, hasLength(2));
      expect(sampler.latestMb, equals(110));
    });

    test('evicts oldest samples when max exceeded', () {
      for (var i = 0; i < 8; i++) {
        sampler.addSample(100 + i);
      }
      expect(sampler.samples, hasLength(5));
      expect(sampler.samples.first, equals(103)); // oldest kept
    });

    test('detects monotonic growth', () {
      sampler.addSample(100);
      sampler.addSample(110);
      sampler.addSample(120);
      sampler.addSample(130);
      sampler.addSample(140);
      expect(sampler.isMonotonicallyGrowing, isTrue);
    });

    test('non-monotonic sequence returns false', () {
      sampler.addSample(100);
      sampler.addSample(110);
      sampler.addSample(105);
      sampler.addSample(120);
      expect(sampler.isMonotonicallyGrowing, isFalse);
    });

    test('growthRate calculates MB/sample difference', () {
      sampler.addSample(100);
      sampler.addSample(150);
      expect(sampler.growthRate, equals(50));
    });

    test('reset clears samples', () {
      sampler.addSample(100);
      sampler.reset();
      expect(sampler.samples, isEmpty);
      expect(sampler.latestMb, equals(0));
    });

    test('alternating peaks and valleys are not monotonic', () {
      sampler.addSample(100);
      sampler.addSample(150);
      sampler.addSample(100);
      sampler.addSample(150);
      sampler.addSample(100);
      expect(sampler.isMonotonicallyGrowing, isFalse);
    });

    test('single sample is not monotonically growing', () {
      sampler.addSample(100);
      expect(sampler.isMonotonicallyGrowing, isFalse);
    });

    test('plateau (equal values) is considered monotonically growing', () {
      sampler.addSample(100);
      sampler.addSample(100);
      sampler.addSample(100);
      // Uses < comparison, so equal values are NOT decreasing = monotonic
      expect(sampler.isMonotonicallyGrowing, isTrue);
    });

    test('growthRate with single sample returns 0', () {
      sampler.addSample(100);
      expect(sampler.growthRate, equals(0));
    });

    test('growthRate with empty samples returns 0', () {
      expect(sampler.growthRate, equals(0));
    });
  });
}
