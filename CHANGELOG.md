# Changelog

All notable changes to this project will be documented in this file.

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
