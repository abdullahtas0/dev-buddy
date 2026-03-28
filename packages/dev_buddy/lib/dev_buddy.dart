// dev_buddy/packages/dev_buddy/lib/dev_buddy.dart
/// DevBuddy - Human-readable Flutter diagnostics overlay.
///
/// Translates DevTools metrics into actionable suggestions
/// that developers can understand without deep Flutter internals knowledge.
///
/// ## Quick Start
/// ```dart
/// MaterialApp(
///   builder: (context, child) {
///     return DevBuddyOverlay(
///       modules: [
///         PerformanceModule(),
///         ErrorTranslatorModule(),
///         NetworkModule(),
///         MemoryModule(),
///         RebuildTrackerModule(),
///       ],
///       child: child!,
///     );
///   },
/// )
/// ```
///
/// In release builds, DevBuddyOverlay compiles to a transparent pass-through
/// with zero runtime cost via conditional imports and tree-shaking.
library dev_buddy;

// === Re-exports from dev_buddy_engine (via public barrel) ===
export 'package:dev_buddy_engine/dev_buddy_engine.dart'
    hide DevBuddyExporterImpl;

// === Flutter-specific (stays in this package) ===

// Core (Flutter wrappers)
export 'src/core/dev_buddy_module.dart';
export 'src/core/dev_buddy_controller.dart';
export 'src/core/dev_buddy_scope.dart';

// Modules (Flutter hook implementations)
export 'src/modules/performance/performance_module.dart';
export 'src/modules/error_translator/error_translator_module.dart';
export 'src/modules/network/network_module.dart';
export 'src/modules/memory/memory_module.dart';
export 'src/modules/rebuild_tracker/rebuild_tracker_module.dart';

// Network interceptor (dart:io, Flutter-specific)
export 'src/modules/network/network_interceptor.dart';

// UI + Navigation + Export (conditional: real in debug, noop in release)
export 'src/_conditional/dev_buddy_conditional.dart';
