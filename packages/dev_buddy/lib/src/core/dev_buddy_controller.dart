// packages/dev_buddy/lib/src/core/dev_buddy_controller.dart
import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:flutter/foundation.dart';

import 'dev_buddy_module.dart';

/// Flutter-specific controller wrapping [DevBuddyEngine].
///
/// Exposes engine state via [ValueNotifier]s for reactive widget rebuilds.
/// All event processing (batching, severity computation, history management)
/// is delegated to the engine.
///
/// This class exists solely to bridge the pure Dart engine with Flutter's
/// widget system. If you don't need Flutter UI, use [DevBuddyEngine] directly.
class DevBuddyController {
  final DevBuddyEngine _engine;
  final List<DevBuddyModule> _flutterModules;

  /// All collected diagnostic events, newest first.
  final ValueNotifier<List<DevBuddyEvent>> events =
      ValueNotifier(const []);

  /// The highest severity among recent events.
  final ValueNotifier<Severity> overallSeverity =
      ValueNotifier(Severity.info);

  /// Count of events dropped due to history limit.
  final ValueNotifier<int> droppedEventCount = ValueNotifier(0);

  DevBuddyController({
    required List<DevBuddyModule> modules,
    DevBuddyConfig config = const DevBuddyConfig(),
  })  : _flutterModules = List.unmodifiable(modules),
        _engine = DevBuddyEngine(
          modules: modules, // DevBuddyModule extends DiagnosticModule
          config: config,
        ) {
    // Bridge: engine state changes → ValueNotifier updates
    _engine.onStateChanged = _syncState;
  }

  /// The underlying engine. Exposed for MCP server and plugin registration.
  DevBuddyEngine get engine => _engine;

  /// Flutter modules (with UI capabilities).
  List<DevBuddyModule> get modules => _flutterModules;

  /// Engine config.
  DevBuddyConfig get config => _engine.config;

  /// Initializes all registered modules. Call once when overlay mounts.
  void initialize() => _engine.initialize();

  bool _disposed = false;

  /// Disposes all modules and releases resources.
  /// Safe to call multiple times (idempotent).
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _engine.dispose();
    events.dispose();
    overallSeverity.dispose();
    droppedEventCount.dispose();
  }

  /// Returns events filtered by [moduleId].
  List<DevBuddyEvent> eventsForModule(String moduleId) =>
      _engine.eventsForModule(moduleId);

  /// Clears all events and resets severity.
  void clearEvents() {
    _engine.clearEvents();
    // Engine callback will sync state, but also update immediately
    events.value = const [];
    overallSeverity.value = Severity.info;
    droppedEventCount.value = 0;
  }

  /// Forces immediate flush of pending events. For testing only.
  @visibleForTesting
  void flushForTesting() => _engine.flushForTesting();

  /// Sync engine state → ValueNotifiers (called by engine after each flush).
  void _syncState(List<DevBuddyEvent> eventList, Severity severity) {
    events.value = List.unmodifiable(eventList);
    overallSeverity.value = severity;
    droppedEventCount.value = _engine.eventBus.droppedCount;
  }
}
