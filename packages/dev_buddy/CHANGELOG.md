# Changelog

## 0.2.0

### Added
- `DevBuddyDiagnosticServer` — Debug-only HTTP server for MCP bridge on localhost:8585
- `enableMcpServer` and `mcpServerPort` parameters on `DevBuddyOverlayImpl`
- Dark mode support in diagnostic panel
- i18n string activation in panel UI
- Conditional compilation: debug = full overlay, release = zero bytes

### Changed
- `DevBuddyController` now delegates to `DevBuddyEngine`
- `DevBuddyModule` now extends `DiagnosticModule` from engine
- NetworkModule periodic cleanup timer (60s) prevents idle memory leak
- Event batching upgraded from fixed 500ms to adaptive 3-tier priority system

### Fixed
- FPS listener leak in overlay dispose
- RebuildTracker callback explosion (100 rebuilds → 100 callbacks per frame)
- Error handler chaining safety (try-catch on previous handlers)
- DraggablePill off-screen drag (bounds clamping)

## 0.1.0

### Added
- Core plugin architecture with `DevBuddyModule` abstract class
- `PerformanceModule` - FPS monitoring and jank detection via `SchedulerBinding`
- `ErrorTranslatorModule` - 25+ Flutter error patterns with human-readable translations
- `NetworkModule` - HTTP traffic monitoring via `HttpOverrides` (works with any HTTP client)
- `MemoryModule` - RSS memory sampling with leak heuristic detection
- `RebuildTrackerModule` - Widget rebuild counting with `Type`-based keys for performance
- `DevBuddyOverlayImpl` - Draggable floating pill with severity-based coloring
- `DevBuddyPanel` - Bottom sheet with animated slide-up and module tabs
- `DevBuddyNavigatorObserverImpl` - Per-screen metrics tracking
- `DevBuddyExporterImpl` - JSON and text report export
- i18n support (English and Turkish)
- `DevBuddyConfig` for customizable thresholds
- Event batching (500ms) to prevent UI thrashing
- Zero external dependencies in core package
- 155 tests across all packages
