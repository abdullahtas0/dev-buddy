import 'config.dart';
import 'event.dart';

/// Pure Dart diagnostic module interface — no Flutter dependency.
///
/// This is the headless module contract. Modules implementing this interface
/// can run in any Dart environment: CLI tools, MCP servers, DevTools extensions,
/// or the Flutter overlay (via [FlutterModule] in the `dev_buddy` package).
///
/// Each module is responsible for:
/// 1. Hooking into a data source during [initialize]
/// 2. Emitting [DevBuddyEvent]s via the [onEvent] callback
/// 3. Cleaning up resources during [dispose]
abstract class DiagnosticModule {
  /// Unique identifier for this module (e.g., 'performance', 'network').
  String get id;

  /// Human-readable display name (e.g., 'Performance', 'Network').
  String get displayName;

  /// Initialize the module with config and event callback.
  ///
  /// The [onEvent] callback is the sole communication channel — modules
  /// push events through it, and the engine distributes them.
  void initialize({
    required DevBuddyConfig config,
    required void Function(DevBuddyEvent event) onEvent,
  });

  /// Release all resources. Safe to call multiple times (idempotent).
  void dispose();

  /// Current module state as a serializable map.
  ///
  /// Used by MCP server and DevTools extension to query module state
  /// without going through the event system.
  Map<String, dynamic> get currentState;
}
