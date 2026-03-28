// packages/dev_buddy/test/modules/performance/frame_analyzer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/modules/performance/frame_analyzer.dart';

void main() {
  group('FrameAnalyzer', () {
    late FrameAnalyzer analyzer;

    setUp(() {
      analyzer = FrameAnalyzer(windowSize: 10);
    });

    test('calculates average FPS from frame durations', () {
      // 10 frames at 16ms each = ~62.5 FPS
      for (var i = 0; i < 10; i++) {
        analyzer.addFrameDuration(const Duration(milliseconds: 16));
      }
      expect(analyzer.averageFps, closeTo(62.5, 1.0));
    });

    test('detects jank when frame exceeds threshold', () {
      final result = analyzer.analyzeFrame(
        duration: const Duration(milliseconds: 32),
        thresholdMs: 16.7,
      );
      expect(result.isJank, isTrue);
      expect(result.durationMs, equals(32));
    });

    test('does not flag normal frames as jank', () {
      final result = analyzer.analyzeFrame(
        duration: const Duration(milliseconds: 14),
        thresholdMs: 16.7,
      );
      expect(result.isJank, isFalse);
    });

    test('sliding window evicts oldest frames', () {
      for (var i = 0; i < 15; i++) {
        analyzer.addFrameDuration(const Duration(milliseconds: 16));
      }
      // Window size is 10, so only last 10 are kept
      expect(analyzer.frameCount, equals(10));
    });

    test('resets state', () {
      analyzer.addFrameDuration(const Duration(milliseconds: 16));
      analyzer.reset();
      expect(analyzer.frameCount, equals(0));
      expect(analyzer.averageFps, equals(0));
    });

    test('returns 0 FPS for empty window', () {
      expect(analyzer.averageFps, equals(0));
    });

    test('handles window size of 1', () {
      final smallAnalyzer = FrameAnalyzer(windowSize: 1);
      smallAnalyzer.addFrameDuration(const Duration(milliseconds: 10));
      expect(smallAnalyzer.averageFps, closeTo(100, 1.0));
      smallAnalyzer.addFrameDuration(const Duration(milliseconds: 20));
      expect(smallAnalyzer.frameCount, equals(1));
      expect(smallAnalyzer.averageFps, closeTo(50, 1.0));
    });

    test('running sum stays accurate after window eviction', () {
      // Fill window with 10ms frames
      for (var i = 0; i < 10; i++) {
        analyzer.addFrameDuration(const Duration(milliseconds: 10));
      }
      // Now add 5 frames at 20ms - should evict 5 oldest 10ms frames
      for (var i = 0; i < 5; i++) {
        analyzer.addFrameDuration(const Duration(milliseconds: 20));
      }
      // Window: 5 frames @ 10ms + 5 frames @ 20ms = 150ms total / 10 = 15ms avg
      const expectedFps = 1000.0 / 15.0;
      expect(analyzer.averageFps, closeTo(expectedFps, 1.0));
    });

    test('handles zero-duration frames', () {
      analyzer.addFrameDuration(Duration.zero);
      expect(analyzer.averageFps, equals(0)); // avgMs <= 0 returns 0
    });

    test('frame at exact threshold boundary is not jank', () {
      final result = analyzer.analyzeFrame(
        duration: const Duration(milliseconds: 17),
        thresholdMs: 17.0,
      );
      // 17ms is NOT > 17.0ms, so not jank (uses > not >=)
      expect(result.isJank, isFalse);
    });
  });
}
