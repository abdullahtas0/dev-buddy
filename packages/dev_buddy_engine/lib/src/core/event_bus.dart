import 'dart:async';

import 'event.dart';
import 'severity.dart';

/// Stream-based event distribution system for the DevBuddy engine.
///
/// Provides pub/sub semantics with history retention for time-travel,
/// MCP queries, and crash replay. Pure Dart — no Flutter dependency.
///
/// History is bounded by [maxHistory] to prevent unbounded memory growth.
class EventBus {
  final int maxHistory;
  final _controller = StreamController<DevBuddyEvent>.broadcast();
  final List<DevBuddyEvent> _history = [];
  int _droppedCount = 0;

  EventBus({this.maxHistory = 500});

  /// Stream of all events. Multiple listeners supported (broadcast).
  Stream<DevBuddyEvent> get stream => _controller.stream;

  /// Filtered stream: only events from [moduleId].
  Stream<DevBuddyEvent> forModule(String moduleId) =>
      _controller.stream.where((e) => e.module == moduleId);

  /// Filtered stream: only events at or above [minSeverity].
  Stream<DevBuddyEvent> ofSeverity(Severity minSeverity) =>
      _controller.stream.where((e) => e.severity.isAtLeast(minSeverity));

  /// Immutable view of event history, newest first.
  ///
  /// Internally stored oldest-first for O(1) append; reversed on read.
  List<DevBuddyEvent> get history => List.unmodifiable(_history.reversed);

  /// Number of events dropped due to history limit.
  int get droppedCount => _droppedCount;

  /// Number of events currently in history.
  int get length => _history.length;

  /// Whether this event bus has been disposed.
  bool get isDisposed => _controller.isClosed;

  /// History utilization as a percentage (0.0 to 1.0).
  /// Useful for monitoring backpressure — values near 1.0 indicate
  /// high event throughput and frequent evictions.
  double get utilizationPercent =>
      maxHistory > 0 ? _history.length / maxHistory : 0;

  /// Emit an event to all listeners and append to history.
  ///
  /// O(1) amortized — uses append instead of insert-at-head.
  void emit(DevBuddyEvent event) {
    if (_controller.isClosed) return;
    _history.add(event);
    if (_history.length > maxHistory) {
      _history.removeAt(0);
      _droppedCount++;
    }
    _controller.add(event);
  }

  /// Emit a batch of events. More efficient than individual emits
  /// when processing a flush from the main thread batch buffer.
  void emitBatch(List<DevBuddyEvent> events) {
    if (_controller.isClosed) return;
    for (final event in events) {
      _history.add(event);
      _controller.add(event);
    }
    // Enforce limit after batch — remove oldest entries from front
    while (_history.length > maxHistory) {
      _history.removeAt(0);
      _droppedCount++;
    }
  }

  /// Events for a specific module, from history (newest first).
  List<DevBuddyEvent> historyFor(String moduleId) =>
      _history.reversed.where((e) => e.module == moduleId).toList();

  /// Clear all history and reset dropped count.
  void clear() {
    _history.clear();
    _droppedCount = 0;
  }

  /// Release resources. No more events can be emitted after this.
  void dispose() {
    _controller.close();
    _history.clear();
  }
}
