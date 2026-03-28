// packages/dev_buddy/lib/src/modules/performance/frame_analyzer.dart
import 'dart:collection';

/// Result of analyzing a single frame.
class FrameAnalysisResult {
  final double durationMs;
  final bool isJank;
  final double thresholdMs;

  const FrameAnalysisResult({
    required this.durationMs,
    required this.isJank,
    required this.thresholdMs,
  });
}

/// Maintains a sliding window of frame durations and computes FPS metrics.
///
/// Pure computation - no Flutter dependency. Testable in isolation.
/// Uses a running sum for O(1) [averageFps] with zero allocation per frame.
class FrameAnalyzer {
  final int windowSize;
  final Queue<Duration> _frameDurations = Queue();

  /// Running sum of frame durations in milliseconds.
  /// Updated incrementally in [addFrameDuration] to avoid
  /// per-frame iterator allocation in [averageFps].
  int _totalMs = 0;

  FrameAnalyzer({this.windowSize = 60});

  int get frameCount => _frameDurations.length;

  /// Adds a frame duration to the sliding window.
  void addFrameDuration(Duration duration) {
    _frameDurations.addLast(duration);
    _totalMs += duration.inMilliseconds;
    if (_frameDurations.length > windowSize) {
      _totalMs -= _frameDurations.removeFirst().inMilliseconds;
    }
  }

  /// Computes average FPS over the sliding window.
  /// O(1) cost — uses a running sum instead of iterating the queue.
  double get averageFps {
    if (_frameDurations.isEmpty) return 0;
    final avgMs = _totalMs / _frameDurations.length;
    if (avgMs <= 0) return 0;
    return 1000.0 / avgMs;
  }

  /// Analyzes a single frame against the jank threshold.
  FrameAnalysisResult analyzeFrame({
    required Duration duration,
    required double thresholdMs,
  }) {
    final ms = duration.inMilliseconds.toDouble();
    return FrameAnalysisResult(
      durationMs: ms,
      isJank: ms > thresholdMs,
      thresholdMs: thresholdMs,
    );
  }

  void reset() {
    _frameDurations.clear();
    _totalMs = 0;
  }
}
