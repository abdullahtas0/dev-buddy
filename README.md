# DevBuddy

**Unified Flutter Debugging Platform** — Not Metrics, Solutions.

The successor to ByteDance's flutter_ume. One tool to replace DevTools context-switching, scattered logging packages, and manual debugging.

## What Makes DevBuddy Different

| Feature | DevTools | Talker | Alice/Chucker | **DevBuddy** |
|---------|---------|--------|---------------|-------------|
| In-app overlay | - | - | Partial | **Full** |
| Performance monitoring | External | - | - | **Built-in** |
| Network inspection | Basic | - | Yes | **Waterfall + Body** |
| Error translation | - | Logging | - | **25+ patterns** |
| Memory leak detection | External | - | - | **Built-in** |
| State time-travel | - | - | - | **Universal** |
| AI integration (MCP) | - | - | - | **9 tools** |
| Accessibility audit | - | - | - | **WCAG 2.1** |
| Plugin architecture | - | - | - | **Extensible** |
| Release overhead | N/A | Minimal | Minimal | **Zero** |

## Quick Start

```dart
// 1. Add to pubspec.yaml
// dev_buddy: ^0.2.0

// 2. Wrap your app
MaterialApp(
  builder: (context, child) => DevBuddyOverlayImpl(
    modules: [
      PerformanceModule(),
      ErrorTranslatorModule(),
      NetworkModule(),
      MemoryModule(),
      RebuildTrackerModule(),
    ],
    child: child!,
  ),
)
```

In release builds, DevBuddy compiles to zero bytes via tree-shaking.

## Packages

| Package | Description |
|---------|-------------|
| [`dev_buddy_engine`](packages/dev_buddy_engine/) | Pure Dart engine — EventBus, StateStore, analyzers, sanitization |
| [`dev_buddy`](packages/dev_buddy/) | Flutter overlay with 5 diagnostic modules and dark mode |
| [`dev_buddy_dio`](packages/dev_buddy_dio/) | Dio HTTP interceptor with header/body capture |
| [`dev_buddy_http`](packages/dev_buddy_http/) | http package wrapper with enriched events |
| [`dev_buddy_riverpod`](packages/dev_buddy_riverpod/) | Riverpod state tracking for time-travel debugging |
| [`dev_buddy_bloc`](packages/dev_buddy_bloc/) | BLoC/Cubit state tracking for time-travel debugging |
| [`dev_buddy_mcp`](packages/dev_buddy_mcp/) | MCP server — AI IDEs query live diagnostics |
| [`dev_buddy_devtools`](packages/dev_buddy_devtools/) | Flutter DevTools extension |

## Architecture

```
dev_buddy_engine (Pure Dart, zero deps)
    ├── dev_buddy (Flutter overlay)
    ├── dev_buddy_dio (Dio adapter)
    ├── dev_buddy_http (http adapter)
    ├── dev_buddy_riverpod (State tracking)
    ├── dev_buddy_bloc (State tracking)
    ├── dev_buddy_mcp (AI integration)
    └── dev_buddy_devtools (DevTools extension)
```

### Engine Highlights

- **Adaptive Batching** — IMMEDIATE (errors), FAST (network), LAZY (metrics)
- **State Time-Travel** — Ring buffer with 20MB RAM budget, hashCode pre-filter
- **Cross-Signal Correlation** — 5 rules: jank+rebuilds, memory+navigation, slow network+jank, auth failures, large response
- **PII Sanitization** — Headers, email, credit card, JWT, API keys automatically scrubbed
- **Accessibility Audit** — WCAG 2.1 touch targets, semantic labels, image descriptions
- **Performance Baselines** — Auto-detect regressions between builds
- **Crash-Safe Logging** — .jsonl audit log survives app crashes

## AI Integration (MCP)

DevBuddy exposes 9 MCP tools for Claude Code, Cursor, and Copilot:

```
dev_buddy/diagnostics      — Compact snapshot: FPS, memory, top issues
dev_buddy/suggest          — AI-friendly fix suggestions
dev_buddy/search_events    — Query events by module/severity/text
dev_buddy/search_network   — Filter requests by URL/status/duration
dev_buddy/search_state     — Query state change history
dev_buddy/detail           — Full event details (lazy loading)
dev_buddy/performance      — Frame timing and jank analysis
dev_buddy/memory           — Memory trend and leak detection
dev_buddy/errors           — Error catalog matches with fixes
```

## Development

```bash
dart pub global activate melos
melos bootstrap
melos run test              # 281+ tests
melos run qualitycheck      # Full CI: clean + lint + test
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, code style, and PR process.

## License

MIT License. See [LICENSE](LICENSE) for details.
