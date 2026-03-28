import 'dart:async';

import 'event.dart';
import 'severity.dart';

/// Priority level for event batching.
///
/// Controls how quickly events are flushed to the worker:
/// - [immediate]: Flushed without delay (errors, crashes)
/// - [fast]: Batched with short delay (network, state changes)
/// - [lazy]: Batched with long delay (metrics, frame timing)
enum EventPriority {
  /// Flushed immediately — no batching delay.
  /// For: errors, crashes, auth failures.
  immediate,

  /// Short batch window (50ms).
  /// For: network requests, state changes.
  fast,

  /// Standard batch window (500ms).
  /// For: frame timing, rebuild counts, memory samples.
  lazy,
}

/// Adaptive event batch buffer inspired by Nagle's algorithm.
///
/// Accumulates events and flushes them based on priority:
/// - IMMEDIATE events trigger an instant flush of the entire buffer
/// - FAST events are held for up to 50ms
/// - LAZY events are held for up to 500ms
///
/// This ensures developers see critical events (errors, network) instantly
/// while low-priority metrics (FPS, memory) are batched efficiently.
class BatchBuffer {
  static const Duration _fastDelay = Duration(milliseconds: 50);
  static const Duration _lazyDelay = Duration(milliseconds: 500);

  final void Function(List<DevBuddyEvent> batch) onFlush;
  final List<DevBuddyEvent> _buffer = [];
  Timer? _fastTimer;
  Timer? _lazyTimer;
  bool _disposed = false;

  BatchBuffer({required this.onFlush});

  /// Add an event to the buffer with the given priority.
  void add(DevBuddyEvent event, {EventPriority priority = EventPriority.lazy}) {
    if (_disposed) return;
    _buffer.add(event);

    switch (priority) {
      case EventPriority.immediate:
        _flush();
      case EventPriority.fast:
        _fastTimer ??= Timer(_fastDelay, _flush);
      case EventPriority.lazy:
        _lazyTimer ??= Timer(_lazyDelay, _flush);
    }
  }

  /// Determine priority from event content.
  static EventPriority priorityFor(DevBuddyEvent event) {
    if (event.severity == Severity.critical) return EventPriority.immediate;
    if (event.module == 'error_translator') return EventPriority.immediate;

    // Network events should appear quickly
    if (event.module == 'network') return EventPriority.fast;

    return EventPriority.lazy;
  }

  /// Force flush all buffered events immediately.
  void flush() => _flush();

  void _flush() {
    _fastTimer?.cancel();
    _fastTimer = null;
    _lazyTimer?.cancel();
    _lazyTimer = null;

    if (_buffer.isEmpty) return;
    final batch = List<DevBuddyEvent>.of(_buffer);
    _buffer.clear();
    onFlush(batch);
  }

  /// Release resources.
  void dispose() {
    _disposed = true;
    _flush(); // Flush remaining events
    _fastTimer?.cancel();
    _lazyTimer?.cancel();
  }
}
