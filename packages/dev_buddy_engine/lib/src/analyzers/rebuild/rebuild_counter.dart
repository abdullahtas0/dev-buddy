// packages/dev_buddy/lib/src/modules/rebuild_tracker/rebuild_counter.dart

/// Tracks widget rebuild counts per Type.
///
/// Uses [Type] as Map key (identity comparison, very fast) instead of
/// String to avoid expensive .toString() calls in the hot path.
/// Only converts to String when displaying in UI via [topRebuildersAsString].
class RebuildCounter {
  final Map<Type, int> _totalCounts = {};
  int _frameCount = 0;
  int _totalFrames = 0;
  DateTime _sessionStart = DateTime.now();

  int get frameRebuildCount => _frameCount;

  /// Total frames tracked since last reset.
  int get totalFrames => _totalFrames;

  /// How long this tracking session has been running.
  Duration get sessionDuration => DateTime.now().difference(_sessionStart);

  void recordRebuild(Type widgetType) {
    _totalCounts[widgetType] = (_totalCounts[widgetType] ?? 0) + 1;
    _frameCount++;
  }

  int countFor(Type widgetType) => _totalCounts[widgetType] ?? 0;

  /// Returns the top N widget types by rebuild count, sorted descending.
  /// Uses Type keys (fast for computation).
  List<MapEntry<Type, int>> topRebuilders(int n) {
    final sorted = _totalCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  /// Returns top rebuilders as String entries (for UI display only).
  /// .toString() is only called here, not in the hot recording path.
  List<MapEntry<String, int>> topRebuildersAsString(int n) {
    return topRebuilders(
      n,
    ).map((e) => MapEntry(e.key.toString(), e.value)).toList();
  }

  /// Average rebuilds per second for a given widget type.
  /// Returns 0 if session is too short (<1s).
  double rebuildsPerSecond(Type widgetType) {
    final secs = sessionDuration.inSeconds;
    if (secs < 1) return 0;
    return (_totalCounts[widgetType] ?? 0) / secs;
  }

  /// Average rebuilds per second as string entries (for UI display).
  List<MapEntry<String, String>> topRebuildersPerSecond(int n) {
    final secs = sessionDuration.inSeconds;
    if (secs < 1) {
      return topRebuildersAsString(
        n,
      ).map((e) => MapEntry(e.key, '${e.value}x')).toList();
    }
    return topRebuilders(n).map((e) {
      final perSec = e.value / secs;
      final total = e.value;
      return MapEntry(
        e.key.toString(),
        '${perSec.toStringAsFixed(0)}/s (${_formatCount(total)} total)',
      );
    }).toList();
  }

  /// Resets per-frame count. Called at end of each frame.
  void resetFrame() {
    _frameCount = 0;
    _totalFrames++;
  }

  void resetAll() {
    _totalCounts.clear();
    _frameCount = 0;
    _totalFrames = 0;
    _sessionStart = DateTime.now();
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
