import 'dart:async';

/// An immutable snapshot of application state at a point in time.
///
/// State is stored as a serialized JSON string (not a live Dart object)
/// to enable garbage collection of the original object and prevent
/// memory leaks. This is a Design Review v2 requirement.
class StateSnapshot {
  /// Auto-incrementing version number.
  final int version;

  /// When this snapshot was captured.
  final DateTime timestamp;

  /// Source identifier (e.g., 'riverpod:counterProvider', 'bloc:CounterBloc').
  final String source;

  /// Full serialized state as JSON string (only for anchor snapshots).
  /// Null for diff-only snapshots — reconstruct by applying diffs from anchor.
  final String? serializedState;

  /// Action/event name that triggered this change (e.g., 'Increment').
  final String? action;

  /// Serialized diff from previous snapshot as JSON string.
  /// Null for anchor snapshots (which store full state).
  final String? serializedDiff;

  /// Whether this is an anchor snapshot (full state) or diff-only.
  final bool isAnchor;

  /// Estimated size in bytes for RAM budget tracking.
  final int estimatedSizeBytes;

  const StateSnapshot({
    required this.version,
    required this.timestamp,
    required this.source,
    this.serializedState,
    this.action,
    this.serializedDiff,
    this.isAnchor = false,
    this.estimatedSizeBytes = 0,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
    'source': source,
    if (action != null) 'action': action,
    'is_anchor': isAnchor,
    if (serializedState != null) 'state': serializedState,
    if (serializedDiff != null) 'diff': serializedDiff,
  };
}

/// Memory-bounded state store using a ring buffer.
///
/// Design principles (from Design Review v2):
/// - **Ring Buffer:** Fixed-capacity circular buffer, oldest entries overwritten.
/// - **RAM Budget:** Hard limit (default 20MB). Evicts oldest when exceeded.
/// - **Diff-Only Storage:** Full state stored every [anchorInterval] entries.
///   In between, only diffs are stored (~5-10x memory savings).
/// - **Serialized Strings:** State stored as JSON strings, NOT live Dart objects.
///   This allows the GC to collect original objects.
/// - **hashCode Pre-Filter:** If state hashCode hasn't changed, skip entirely.
///   Prevents false positives from Map key ordering differences.
class StateStore {
  /// Maximum RAM budget in bytes.
  final int maxBudgetBytes;

  /// Store full state every N entries (anchor snapshot).
  final int anchorInterval;

  final List<StateSnapshot> _ring = [];
  final _controller = StreamController<StateSnapshot>.broadcast();
  int _version = 0;
  int _totalSizeBytes = 0;

  /// Anchor tracking per source — ensures each source gets its own anchors.
  final Map<String, int> _snapshotsSinceAnchor = {};

  /// Last hashCode per source — for best-effort pre-filtering.
  ///
  /// Hash collisions are possible: two different states may produce the
  /// same hashCode. The version counter ([_lastVersions]) provides a
  /// secondary check — if the version differs, the state is recorded
  /// even when hashCodes collide.
  final Map<String, int> _lastHashCodes = {};

  /// Monotonic version per source — secondary guard against hash collisions.
  final Map<String, int> _lastVersions = {};

  StateStore({
    this.maxBudgetBytes = 20 * 1024 * 1024, // 20MB
    this.anchorInterval = 50,
  });

  /// Stream of new snapshots.
  Stream<StateSnapshot> get stream => _controller.stream;

  /// All snapshots, newest first.
  List<StateSnapshot> get history => List.unmodifiable(_ring.reversed.toList());

  /// Number of stored snapshots.
  int get length => _ring.length;

  /// Current RAM usage in bytes.
  int get usedBytes => _totalSizeBytes;

  /// RAM budget usage as percentage (0.0 to 1.0+).
  double get budgetUsagePercent =>
      maxBudgetBytes > 0 ? _totalSizeBytes / maxBudgetBytes : 0;

  /// Record a state change.
  ///
  /// [source] identifies the state provider (e.g., 'riverpod:counterProvider').
  /// [hashCode] is the hash of the new state — used for pre-filtering.
  /// [serializedState] is the full JSON string (for anchors).
  /// [serializedDiff] is the diff from previous (for non-anchors).
  /// [action] is the name of the event/action that triggered this change.
  ///
  /// Returns true if the snapshot was recorded, false if skipped
  /// (hashCode unchanged and no explicit version bump).
  bool record({
    required String source,
    required int stateHashCode,
    String? serializedState,
    String? serializedDiff,
    String? action,
    int? sourceVersion,
  }) {
    // hashCode pre-filter: skip if state hasn't actually changed.
    // Secondary check: if caller provides a sourceVersion that differs
    // from the last recorded version, record even on hash collision.
    if (_lastHashCodes[source] == stateHashCode) {
      if (sourceVersion == null || _lastVersions[source] == sourceVersion) {
        return false;
      }
    }
    _lastHashCodes[source] = stateHashCode;
    if (sourceVersion != null) _lastVersions[source] = sourceVersion;

    _version++;
    final sourceCount = (_snapshotsSinceAnchor[source] ?? 0) + 1;
    _snapshotsSinceAnchor[source] = sourceCount;

    final isAnchor = sourceCount >= anchorInterval;
    if (isAnchor) _snapshotsSinceAnchor[source] = 0;

    final data = isAnchor
        ? serializedState
        : (serializedDiff ?? serializedState);
    final estimatedSize =
        (data?.length ?? 0) +
        (source.length) +
        (action?.length ?? 0) +
        64; // overhead for other fields

    final snapshot = StateSnapshot(
      version: _version,
      timestamp: DateTime.now(),
      source: source,
      serializedState: isAnchor ? serializedState : null,
      serializedDiff: isAnchor ? null : serializedDiff,
      action: action,
      isAnchor: isAnchor,
      estimatedSizeBytes: estimatedSize,
    );

    // Enforce RAM budget — evict oldest entries
    while (_totalSizeBytes + estimatedSize > maxBudgetBytes &&
        _ring.isNotEmpty) {
      _evictOldest();
    }

    _ring.add(snapshot);
    _totalSizeBytes += estimatedSize;

    if (!_controller.isClosed) {
      _controller.add(snapshot);
    }

    return true;
  }

  /// Get snapshot at a specific version.
  StateSnapshot? at(int version) {
    for (final snap in _ring) {
      if (snap.version == version) return snap;
    }
    return null;
  }

  /// Get snapshots for a specific source.
  List<StateSnapshot> forSource(String source) =>
      _ring.where((s) => s.source == source).toList();

  /// Get the N most recent snapshots.
  List<StateSnapshot> recent(int count) {
    final start = _ring.length > count ? _ring.length - count : 0;
    return _ring.sublist(start).reversed.toList();
  }

  /// Clear all snapshots and reset budget.
  void clear() {
    _ring.clear();
    _totalSizeBytes = 0;
    _snapshotsSinceAnchor.clear();
    _lastHashCodes.clear();
    _lastVersions.clear();
  }

  /// Release resources.
  void dispose() {
    _controller.close();
    clear();
  }

  void _evictOldest() {
    if (_ring.isEmpty) return;
    final removed = _ring.removeAt(0);
    _totalSizeBytes -= removed.estimatedSizeBytes;
    if (_totalSizeBytes < 0) _totalSizeBytes = 0;
  }
}
