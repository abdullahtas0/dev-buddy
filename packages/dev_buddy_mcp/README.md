# dev_buddy_mcp

MCP (Model Context Protocol) server for [DevBuddy](https://pub.dev/packages/dev_buddy). Exposes Flutter diagnostics as AI-queryable tools for Claude Code, Cursor, and Copilot.

## Installation

```yaml
dependencies:
  dev_buddy_engine: ^0.2.0
  dev_buddy_mcp: ^0.2.0
```

## Available Tools

| Tool | Purpose |
|------|---------|
| `diagnostics` | Compact snapshot of current diagnostic state |
| `suggest` | AI-friendly fix suggestions for active issues |
| `search_events` | Filter events by module and severity |
| `search_network` | Query captured HTTP traffic |
| `search_state` | Browse state history for time-travel debugging |
| `detail` | Drill-down into specific events by index |
| `performance` | FPS and frame timing summary |
| `memory` | Memory usage and leak indicators |
| `errors` | Active errors with translated descriptions |

## Design Principles

- **Summary-first:** `diagnostics()` returns a compact overview to prevent LLM context overflow
- **Query-specific:** AI asks for exactly what it needs, not a data dump
- **Sanitized:** All data passes through `DataSanitizer` before reaching AI consumers
- **Lazy detail:** Drill-down via `detail()` and `search_*` tools

## Usage

```dart
import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:dev_buddy_mcp/dev_buddy_mcp.dart';

final engine = DevBuddyEngine();
engine.initialize();

final tools = McpTools(engine: engine);

// Register tools with your MCP server
for (final def in tools.toolDefinitions) {
  server.addTool(def.name, def.description, tools.tools[def.name]!);
}
```

## Related Packages

- [dev_buddy](https://pub.dev/packages/dev_buddy) - Flutter diagnostics overlay
- [dev_buddy_engine](https://pub.dev/packages/dev_buddy_engine) - Pure Dart diagnostic engine
