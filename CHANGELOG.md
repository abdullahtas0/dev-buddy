# Changelog

All notable changes to this project will be documented in this file.

## [0.2.1] - 2026-03-28

### Added
- **Typed event metadata** — Sealed `EventMetadata` hierarchy (Performance, Network, Rebuild, Memory, Correlation, Custom) with backwards-compatible `metadata` Map accessor
- **MCP pagination** — `offset` parameter on `search_events`, `search_network`, `search_state` tools
- **Correlation runtime API** — `addRule()`, `removeRule()`, `replaceRules()` for dynamic rule management
- **DataSanitizer patterns** — GCP API key, GitHub token, SSN, phone number, strict-mode IP address (14 total, was 9)
- **HTTP adapter streaming safety** — `maxCaptureBytes` threshold (10MB default); responses above threshold pass through without buffering
- **EventBus monitoring** — `isDisposed`, `utilizationPercent` properties for backpressure awareness
- **StateStore version guard** — Optional `sourceVersion` parameter prevents hash collision false negatives
- 50+ new stress tests (10K events, budget pressure, 5000+ event correlation evaluation)
- Per-package CHANGELOG.md for engine, bloc, mcp, riverpod, devtools
- Per-package README.md for bloc, mcp, riverpod, devtools

### Changed
- **EventBus O(1) performance** — Switched from `insert(0, ...)` to `add()` + reversed view
- **Dependency inversion** — `dev_buddy_dio` and `dev_buddy_http` now depend on `dev_buddy_engine` (pure Dart) instead of `dev_buddy` (Flutter)
- **Dio request tracking** — Replaced hashCode-based request ID with atomic counter + identityHashCode
- **Diff truncation** — Riverpod/BLoC observers truncate diffs to `maxDiffLength` (1024 chars) to prevent StateStore bloat
- **Correlation constants** — Extracted magic numbers to named constants (`networkJankWindowMs`, `authFailureThreshold`, `largeResponseThresholdBytes`)
- All packages aligned to version 0.2.0 (dev_buddy, dev_buddy_dio, dev_buddy_http were at 0.1.0)
- Publish workflow now includes all 8 packages (was 3)
- Example app uses root analysis_options.yaml

### Fixed
- **DevTools error safety** — All service extension handlers wrapped in `_safeHandle()` try-catch
- **NetworkModule memory leak** — Added periodic cleanup timer (60s) for request list
- **HTTP adapter OOM** — Large responses no longer buffered entirely in RAM

## [0.2.0] - 2026-03-28

### Added
- **dev_buddy_engine** — Pure Dart diagnostic engine (zero Flutter dependency)
  - `DevBuddyEngine` with adaptive `BatchBuffer` (IMMEDIATE/FAST/LAZY priorities)
  - `EventBus` — Stream-based event distribution with history
  - `StateStore` — Ring buffer with RAM budget (20MB default), hashCode pre-filter, anchor/diff strategy
  - `PluginRegistry` — Community-extensible plugin architecture with dependency resolution
  - `CorrelationEngine` — 5 built-in cross-signal correlation rules
  - `AccessibilityAuditor` — WCAG 2.1 touch target, semantic label, image description audit
  - `RegressionDetector` — Performance baseline comparison with configurable tolerance
  - `DataSanitizer` — 3-tier PII scrubbing (headers, regex patterns, body truncation)
  - `AuditLog` — Crash-safe .jsonl persistence for crash replay
  - `MarkdownExporter` — GitHub-flavored diagnostic report generation
- **dev_buddy_riverpod** — Riverpod `ProviderObserver` for state time-travel
- **dev_buddy_bloc** — BLoC/Cubit `BlocObserver` for state time-travel
- **dev_buddy_mcp** — MCP server with 9 AI-queryable diagnostic tools
- **dev_buddy_devtools** — Flutter DevTools extension with service extensions
- Enriched `NetworkRequestEvent` with headers, body, content-type, timeline
- Conditional compilation: debug = full overlay, release = zero bytes
- Dark mode support in diagnostic panel
- i18n string activation in panel UI
- ShopBuddy example app (realistic e-commerce with DevBuddy diagnostics)
- GitHub Actions CI/CD workflows

### Changed
- `DevBuddyController` now delegates to `DevBuddyEngine`
- `DevBuddyModule` now extends `DiagnosticModule` from engine
- Dio/http adapters depend on engine (not Flutter) for lighter dependency tree
- Event batching upgraded from fixed 500ms to adaptive 3-tier priority system

### Fixed
- FPS listener leak in overlay dispose
- RebuildTracker callback explosion (100 rebuilds → 100 callbacks per frame)
- Error handler chaining safety (try-catch on previous handlers)
- DraggablePill off-screen drag (bounds clamping)
- ErrorCatalog mutability (deprecated addPattern, added immutable API)
- FrameAnalyzer O(1) FPS with running sum (was O(n) per frame)
- Dio adapter timestamp memory leak (orphan cleanup)
- StateStore per-source anchor tracking
- Correlation temporal check direction
- JWT regex in sanitizer (added `-` to base64url character class)

## [0.1.0] - 2026-03-26

### Added
- Core plugin architecture with `DevBuddyModule` abstract class
- 5 diagnostic modules: Performance, Error Translator, Network, Memory, Rebuild Tracker
- Draggable floating pill overlay with severity-based coloring
- Bottom sheet diagnostic panel with module tabs
- Navigator observer for per-screen metrics
- JSON and text report export
- i18n support (English and Turkish)
- Event batching (500ms) to prevent UI thrashing
- Zero external dependencies in core package
