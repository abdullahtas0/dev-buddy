import '../analyzers/correlation/correlation_engine.dart';
import 'batch_buffer.dart';
import 'config.dart';
import 'event.dart';
import 'event_bus.dart';
import 'module.dart';
import 'plugin.dart';
import 'plugin_registry.dart';
import 'severity.dart';
import 'state_store.dart';

/// Central diagnostic engine — orchestrates modules, events, and processing.
///
/// Pure Dart, no Flutter dependency. The Flutter overlay wraps this engine
/// with [ValueNotifier]-based reactivity for widget rebuilds.
///
/// Event flow:
/// 1. Modules emit events via [onEvent] callback
/// 2. [BatchBuffer] accumulates events with priority-based flushing
/// 3. On flush, events are processed by [EventBus] (history + stream)
/// 4. Overall severity is recomputed
///
/// In a Flutter context, the flush target can be redirected to a Worker
/// Isolate for heavy processing (correlation, diffing, baseline comparison).
class DevBuddyEngine {
  final List<DiagnosticModule> _modules;
  final DevBuddyConfig config;
  final EventBus eventBus;
  final PluginRegistry pluginRegistry = PluginRegistry();
  late final StateStore stateStore;
  final CorrelationEngine correlationEngine;
  late final BatchBuffer _batchBuffer;
  bool _disposed = false;

  /// Current overall severity across all events (read-only from outside).
  Severity _severityLevel = Severity.info;
  Severity get overallSeverity => _severityLevel;

  /// Callback invoked after each batch flush with the latest state.
  /// The Flutter wrapper uses this to update ValueNotifiers.
  void Function(List<DevBuddyEvent> events, Severity severity)? onStateChanged;

  DevBuddyEngine({
    required List<DiagnosticModule> modules,
    DevBuddyConfig? config,
    EventBus? eventBus,
    CorrelationEngine? correlationEngine,
  })  : _modules = List.unmodifiable(modules),
        config = config ?? const DevBuddyConfig(),
        correlationEngine = correlationEngine ?? CorrelationEngine(),
        eventBus = eventBus ?? EventBus(maxHistory: config?.maxEvents ?? 100) {
    _batchBuffer = BatchBuffer(onFlush: _processBatch);
    stateStore = StateStore(
      maxBudgetBytes: this.config.stateStoreBudgetBytes,
    );
  }

  /// Register a plugin. Call before [initialize].
  void registerPlugin(DevBuddyPlugin plugin) {
    pluginRegistry.register(plugin);
  }

  /// Initialize all registered modules and plugins.
  void initialize() {
    for (final module in _modules) {
      module.initialize(
        config: config,
        onEvent: _handleEvent,
      );
    }
    // Initialize plugins after modules (plugins may depend on module data)
    pluginRegistry.validateDependencies();
    for (final plugin in pluginRegistry.all) {
      plugin.onRegister(this);
    }
  }

  /// Dispose all modules, plugins, and release resources.
  /// Safe to call multiple times (idempotent).
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _batchBuffer.dispose();
    pluginRegistry.disposeAll();
    for (final module in _modules) {
      module.dispose();
    }
    stateStore.dispose();
    eventBus.dispose();
  }

  /// List of registered modules (read-only).
  List<DiagnosticModule> get modules => _modules;

  /// Events for a specific module from history.
  List<DevBuddyEvent> eventsForModule(String moduleId) =>
      eventBus.historyFor(moduleId);

  /// Clear all events and reset severity.
  void clearEvents() {
    eventBus.clear();
    correlationEngine.reset();
    _severityLevel = Severity.info;
    onStateChanged?.call(const [], Severity.info);
  }

  /// Force flush any pending events in the batch buffer.
  void flushForTesting() => _batchBuffer.flush();

  /// Snapshot of current engine state for MCP / serialization.
  Map<String, dynamic> snapshot() {
    return {
      'overall_severity': overallSeverity.name,
      'event_count': eventBus.length,
      'dropped_count': eventBus.droppedCount,
      'modules': {
        for (final m in _modules) m.id: m.currentState,
      },
      'plugins': {
        for (final p in pluginRegistry.all) p.id: p.currentState,
      },
      'state_store': {
        'snapshot_count': stateStore.length,
        'used_bytes': stateStore.usedBytes,
        'budget_usage_percent': stateStore.budgetUsagePercent,
      },
      'recent_events': eventBus.history
          .take(10)
          .map((e) => e.toJson())
          .toList(),
    };
  }

  /// Handle an event from a module — add to batch buffer with priority.
  void _handleEvent(DevBuddyEvent event) {
    if (_disposed) return;
    if (!event.severity.isAtLeast(config.minSeverity)) return;
    _batchBuffer.add(event, priority: BatchBuffer.priorityFor(event));
  }

  /// Process a batch of events from the buffer.
  void _processBatch(List<DevBuddyEvent> batch) {
    if (_disposed) return;
    eventBus.emitBatch(batch);

    // Run cross-signal correlation (produces compound insights)
    final insights = correlationEngine.evaluate(eventBus.history);
    if (insights.isNotEmpty) {
      eventBus.emitBatch(insights);
    }

    // Recompute overall severity
    _severityLevel = Severity.highest(
      eventBus.history.map((e) => e.severity),
    );

    // Notify Flutter wrapper (if attached)
    onStateChanged?.call(eventBus.history, overallSeverity);
  }
}
