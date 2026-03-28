// packages/dev_buddy/lib/src/modules/rebuild_tracker/rebuild_counter.dart

/// Tracks widget rebuild counts per Type.
///
/// Uses [Type] as Map key (identity comparison, very fast) instead of
/// String to avoid expensive .toString() calls in the hot path.
/// Only converts to String when displaying in UI via [topRebuildersAsString].
class RebuildCounter {
  final Map<Type, int> _totalCounts = {};
  int _frameCount = 0;

  int get frameRebuildCount => _frameCount;

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
    return topRebuilders(n)
        .map((e) => MapEntry(e.key.toString(), e.value))
        .toList();
  }

  /// Resets per-frame count. Called at the start of each frame.
  void resetFrame() {
    _frameCount = 0;
  }

  void resetAll() {
    _totalCounts.clear();
    _frameCount = 0;
  }
}
