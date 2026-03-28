# Changelog

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
