// packages/dev_buddy/lib/src/core/dev_buddy_module.dart
import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:flutter/widgets.dart';

/// Flutter-specific diagnostic module — extends the engine's [DiagnosticModule]
/// with UI capabilities (icon + tab widget).
///
/// All five built-in modules (Performance, Error, Network, Memory, Rebuild)
/// extend this class. Community modules that need in-app UI should also extend
/// this. For headless modules (CLI, MCP), extend [DiagnosticModule] directly.
///
/// Backward compatible: existing code using `DevBuddyModule` continues to work.
abstract class DevBuddyModule extends DiagnosticModule {
  /// Human-readable name shown in the panel tab bar.
  /// Maps to [DiagnosticModule.displayName].
  String get name;

  @override
  String get displayName => name;

  /// Icon shown in the panel tab bar.
  IconData get icon;

  /// Builds the tab content widget shown in the diagnostic panel.
  /// [events] contains only events emitted by this module.
  Widget buildTab(BuildContext context, List<DevBuddyEvent> events);

  /// Default implementation returns basic state info.
  /// Modules can override for richer MCP/serialization data.
  @override
  Map<String, dynamic> get currentState => {'id': id, 'name': name};
}
