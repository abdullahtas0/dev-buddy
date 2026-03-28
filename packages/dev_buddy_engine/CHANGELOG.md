# Changelog

## 0.2.0

### Added
- `DevBuddyEngine` — Central orchestrator with adaptive `BatchBuffer`
- `EventBus` — Stream-based event distribution with bounded history
- `BatchBuffer` — 3-tier adaptive batching (IMMEDIATE/FAST/LAZY priorities)
- `StateStore` — Ring buffer with RAM budget (20MB default), hashCode pre-filter, anchor/diff compression
- `PluginRegistry` — Plugin lifecycle management with dependency resolution
- `CorrelationEngine` — 5 built-in cross-signal correlation rules
- `AccessibilityAuditor` — WCAG 2.1 touch target, semantic label, image description audit
- `RegressionDetector` — Performance baseline comparison with configurable tolerance
- `DataSanitizer` — 3-tier PII scrubbing (9 regex patterns for credit cards, JWT, AWS keys, etc.)
- `AuditLog` — Crash-safe .jsonl persistence with corruption-tolerant parsing
- `MarkdownExporter` — GitHub-flavored diagnostic report generation
- `FrameAnalyzer` — O(1) FPS calculation with running sum
- `JankDetector` — Frame timing threshold evaluation
- `ErrorCatalog` — 25 Flutter error patterns with human-readable translations
- `NetworkAnalyzer` — HTTP status analysis and slow request detection
- `MemorySampler` — RSS sampling with leak heuristic
- `RebuildCounter` / `RebuildReporter` — Widget rebuild frequency tracking
- i18n support (English, Turkish)
- Zero external dependencies (pure Dart)

## 0.1.0

### Added
- Initial engine extraction from dev_buddy package
- Core event model and severity enum
- Basic diagnostic module interface
