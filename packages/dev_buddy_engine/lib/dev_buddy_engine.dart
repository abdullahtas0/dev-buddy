/// DevBuddy Engine — Pure Dart diagnostic engine.
///
/// Zero Flutter dependency. Provides event processing, analyzers,
/// and export for the DevBuddy debugging platform.
library dev_buddy_engine;

// Core
export 'src/core/batch_buffer.dart';
export 'src/core/config.dart';
export 'src/core/engine.dart';
export 'src/core/event.dart';
export 'src/core/event_bus.dart';
export 'src/core/module.dart';
export 'src/core/plugin.dart';
export 'src/core/plugin_registry.dart';
export 'src/core/severity.dart';
export 'src/core/state_store.dart';

// Analyzers - Performance
export 'src/analyzers/performance/frame_analyzer.dart';
export 'src/analyzers/performance/jank_detector.dart';

// Analyzers - Error Translation
export 'src/analyzers/error/error_catalog.dart';
export 'src/analyzers/error/error_pattern.dart';

// Analyzers - Network
export 'src/analyzers/network/network_analyzer.dart';
export 'src/analyzers/network/network_event.dart';
// Note: network_interceptor.dart uses dart:io and lives in dev_buddy (Flutter pkg)

// Analyzers - Memory
export 'src/analyzers/memory/memory_sampler.dart';
export 'src/analyzers/memory/leak_heuristic.dart';

// Analyzers - Rebuild
export 'src/analyzers/rebuild/rebuild_counter.dart';
export 'src/analyzers/rebuild/rebuild_reporter.dart';

// Analyzers - Correlation
export 'src/analyzers/correlation/correlation_engine.dart';

// Analyzers - Accessibility
export 'src/analyzers/accessibility/accessibility_auditor.dart';

// Analyzers - Performance Baseline
export 'src/analyzers/baseline/performance_baseline.dart';

// Export
export 'src/export/audit_log.dart';
export 'src/export/markdown_exporter.dart';
export 'src/export/report_exporter.dart';
export 'src/export/report_model.dart';

// Sanitization
export 'src/sanitization/data_sanitizer.dart';

// i18n
export 'src/i18n/strings.dart';
