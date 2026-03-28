# dev_buddy_engine

Pure Dart diagnostic engine for [DevBuddy](https://pub.dev/packages/dev_buddy). Zero Flutter dependency.

## What Is This?

The engine is the headless brain of DevBuddy. It provides event processing, analyzers, state tracking, and export — all in pure Dart. Use it in:

- Flutter apps (via `dev_buddy` overlay package)
- CLI tools
- MCP servers (via `dev_buddy_mcp`)
- DevTools extensions (via `dev_buddy_devtools`)
- Dart backend services

## Core Components

| Component | Purpose |
|-----------|---------|
| `DevBuddyEngine` | Central orchestrator — modules, events, plugins |
| `EventBus` | Stream-based event distribution with history |
| `BatchBuffer` | Adaptive batching (IMMEDIATE/FAST/LAZY priorities) |
| `StateStore` | Ring buffer with RAM budget for state time-travel |
| `PluginRegistry` | Community plugin management with dependency resolution |
| `CorrelationEngine` | Cross-signal compound diagnostics |
| `DataSanitizer` | PII scrubbing for AI/external consumers |

## Analyzers

| Analyzer | What It Does |
|----------|-------------|
| `FrameAnalyzer` | O(1) FPS calculation with running sum |
| `JankDetector` | Frame timing threshold evaluation |
| `ErrorCatalog` | 25 Flutter error patterns → human-readable translations |
| `NetworkAnalyzer` | HTTP status analysis, slow request detection |
| `MemorySampler` | RSS sampling with leak heuristic |
| `RebuildCounter` | Widget rebuild frequency tracking |
| `AccessibilityAuditor` | WCAG 2.1 touch target + semantic label audit |
| `RegressionDetector` | Performance baseline comparison |
| `CorrelationEngine` | 5 built-in cross-signal rules |

## Usage

```dart
import 'package:dev_buddy_engine/dev_buddy_engine.dart';

final engine = DevBuddyEngine(
  modules: [MyCustomModule()],
  config: const DevBuddyConfig(maxEvents: 200),
);

engine.initialize();
engine.eventBus.stream.listen((event) {
  print('${event.severity.emoji} ${event.title}');
});
```

## Related Packages

- [dev_buddy](https://pub.dev/packages/dev_buddy) — Flutter overlay UI
- [dev_buddy_mcp](https://pub.dev/packages/dev_buddy_mcp) — AI IDE integration
- [dev_buddy_riverpod](https://pub.dev/packages/dev_buddy_riverpod) — Riverpod state tracking
- [dev_buddy_bloc](https://pub.dev/packages/dev_buddy_bloc) — BLoC state tracking
