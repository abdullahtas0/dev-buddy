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

  /// Running sum of frame durations in **microseconds**.
  /// Uses microseconds instead of milliseconds to avoid integer truncation
  /// that causes inflated FPS on 120Hz+ devices (8.3ms → 8ms = 125 FPS instead of 120).
  int _totalUs = 0;

  FrameAnalyzer({this.windowSize = 60});

  int get frameCount => _frameDurations.length;

  /// Adds a frame duration to the sliding window.
  void addFrameDuration(Duration duration) {
    _frameDurations.addLast(duration);
    _totalUs += duration.inMicroseconds;
    if (_frameDurations.length > windowSize) {
      _totalUs -= _frameDurations.removeFirst().inMicroseconds;
    }
  }

  /// Computes average FPS over the sliding window.
  /// O(1) cost — uses a running sum in microseconds for precision.
  /// Microseconds avoids integer truncation that inflates FPS on 120Hz+
  /// (e.g., 8.3ms truncated to 8ms = 125 FPS instead of correct 120).
  /// Maximum reportable FPS. Values above this are clamped to avoid
  /// misleading readings from sub-millisecond idle frames.
  static const double maxFps = 120.0;

  double get averageFps {
    if (_frameDurations.isEmpty) return 0;
    final avgUs = _totalUs / _frameDurations.length;
    if (avgUs <= 0) return 0;
    final fps = 1000000.0 / avgUs;
    return fps.clamp(0.0, maxFps);
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
    _totalUs = 0;
  }
}
