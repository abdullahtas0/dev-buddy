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

  /// Sliding window of vsync-to-vsync intervals (microseconds).
  final Queue<int> _vsyncIntervals = Queue();

  /// Running sums for O(1) averages.
  int _totalBuildUs = 0;
  int _totalVsyncUs = 0;

  /// Last vsync timestamp for computing inter-frame interval.
  int? _lastVsyncUs;

  FrameAnalyzer({this.windowSize = 60});

  int get frameCount => _frameDurations.length;

  /// Adds a frame's build duration to the sliding window for jank detection.
  void addFrameDuration(Duration duration) {
    _frameDurations.addLast(duration);
    _totalBuildUs += duration.inMicroseconds;
    if (_frameDurations.length > windowSize) {
      final removed = _frameDurations.removeFirst();
      _totalBuildUs -= removed.inMicroseconds;
    }
  }

  /// Records the vsync timestamp for accurate FPS calculation.
  ///
  /// FPS = 1 / average(vsync-to-vsync interval). On a 60Hz display,
  /// a frame finishing in 7ms still has a 16.7ms vsync interval,
  /// correctly reporting ~60 FPS instead of 142 FPS.
  /// Maximum vsync interval to consider valid (100ms).
  /// Intervals larger than this indicate idle gaps where no frames
  /// were rendered, and should be excluded from FPS calculation.
  static const int _maxVsyncIntervalUs = 100000; // 100ms = ~10 FPS minimum

  void recordVsyncTimestamp(int vsyncStartUs) {
    if (_lastVsyncUs != null) {
      final delta = vsyncStartUs - _lastVsyncUs!;
      // Only count intervals within active rendering (skip idle gaps)
      if (delta > 0 && delta < _maxVsyncIntervalUs) {
        _vsyncIntervals.addLast(delta);
        _totalVsyncUs += delta;
        if (_vsyncIntervals.length > windowSize) {
          _totalVsyncUs -= _vsyncIntervals.removeFirst();
        }
      }
    }
    _lastVsyncUs = vsyncStartUs;
  }

  /// Computes average FPS based on **vsync intervals** (not build time).
  ///
  /// Matches what DevTools Performance tab shows. Falls back to
  /// build-time-based FPS if no vsync data is available (pure Dart).
  static const double maxFps = 120.0;

  double get averageFps {
    // Prefer vsync-based FPS (accurate)
    if (_vsyncIntervals.isNotEmpty) {
      final avgIntervalUs = _totalVsyncUs / _vsyncIntervals.length;
      if (avgIntervalUs > 0) {
        final fps = 1000000.0 / avgIntervalUs;
        return fps.clamp(0.0, maxFps);
      }
    }

    // Fallback: build-time-based (for pure Dart / testing)
    if (_frameDurations.isEmpty) return 0;
    final avgUs = _totalBuildUs / _frameDurations.length;
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
    _vsyncIntervals.clear();
    _totalBuildUs = 0;
    _totalVsyncUs = 0;
    _lastVsyncUs = null;
  }
}
