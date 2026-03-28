# dev_buddy_mcp

MCP (Model Context Protocol) server for [DevBuddy](https://pub.dev/packages/dev_buddy). Connects your running Flutter app's diagnostics to AI IDEs like Claude Code, Cursor, and VS Code Copilot.

## How It Works

```
Flutter App (debug)          MCP Server              AI IDE
┌──────────────────┐    ┌─────────────────┐    ┌──────────────┐
│ DevBuddyOverlay  │    │ bin/server.dart  │    │ Claude Code  │
│   ↓               │    │                 │    │ or Cursor    │
│ DevBuddyEngine   │◄──►│ HTTP bridge     │◄──►│              │
│   ↓               │HTTP│ (localhost)     │MCP │ "What's      │
│ DiagnosticServer ─┤────┤                 ├────┤  causing     │
│ (port 8585)      │    │ 9 diagnostic    │    │  the jank?"  │
└──────────────────┘    │ tools           │    └──────────────┘
                         └─────────────────┘
```

1. Your Flutter app runs with DevBuddy → collects FPS, errors, network, memory, rebuild data
2. DevBuddy starts an HTTP server on `localhost:8585` (debug only, zero cost in release)
3. The MCP server (`bin/server.dart`) is launched by your AI IDE
4. AI IDE sends tool calls → MCP server → HTTP to Flutter app → returns diagnostics
5. AI reads the diagnostics and suggests fixes in your code

## Setup

### Step 1: Add DevBuddy to Your Flutter App

```yaml
# pubspec.yaml
dependencies:
  dev_buddy: ^0.2.0
```

```dart
// main.dart
import 'package:dev_buddy/dev_buddy.dart';

MaterialApp(
  builder: (context, child) => DevBuddyOverlayImpl(
    enabled: kDebugMode,
    enableMcpServer: true,    // Starts HTTP server on localhost:8585
    mcpServerPort: 8585,      // Default port
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

### Step 2: Configure Claude Code

Add to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "dev-buddy": {
      "command": "dart",
      "args": ["run", "dev_buddy_mcp"],
      "cwd": "/path/to/your/flutter/project"
    }
  }
}
```

Or if you installed the package globally:

```json
{
  "mcpServers": {
    "dev-buddy": {
      "command": "dart",
      "args": ["pub", "global", "run", "dev_buddy_mcp"]
    }
  }
}
```

### Step 3: Run Your App and Ask Claude

1. Run your Flutter app in debug mode: `flutter run`
2. You should see: `🔧 DevBuddy diagnostic server running on http://localhost:8585`
3. Open Claude Code and ask:

```
"Check my running Flutter app for performance issues"
"What network requests are slow?"
"Are there any memory leaks?"
"Why is the FPS dropping?"
```

Claude will use the MCP tools to query your app's live diagnostics and suggest fixes.

## Available Tools

| Tool | What It Does |
|------|-------------|
| `dev_buddy/diagnostics` | Compact snapshot: severity, event count, top 3 issues |
| `dev_buddy/suggest` | AI-friendly fix suggestions for active problems |
| `dev_buddy/search_events` | Filter events by module, severity, or text query |
| `dev_buddy/search_network` | Query HTTP traffic by URL, status, duration |
| `dev_buddy/search_state` | Time-travel through Riverpod/BLoC state changes |
| `dev_buddy/detail` | Full event details by index |
| `dev_buddy/performance` | FPS, frame timing, jank analysis |
| `dev_buddy/memory` | RSS memory, growth rate, leak detection |
| `dev_buddy/errors` | Translated Flutter errors with fix suggestions |

## Custom Port

If port 8585 is taken, use a different port:

```dart
// Flutter app
DevBuddyOverlayImpl(
  mcpServerPort: 9090,
  // ...
)
```

```json
// .mcp.json
{
  "mcpServers": {
    "dev-buddy": {
      "command": "dart",
      "args": ["run", "dev_buddy_mcp", "9090"]
    }
  }
}
```

## VS Code Extension (Copilot/Continue)

For VS Code with MCP-compatible extensions, add to `.vscode/mcp.json`:

```json
{
  "servers": {
    "dev-buddy": {
      "command": "dart",
      "args": ["run", "dev_buddy_mcp"],
      "cwd": "${workspaceFolder}"
    }
  }
}
```

## Cursor IDE

Add to Cursor's MCP settings (Settings > MCP Servers):

```json
{
  "dev-buddy": {
    "command": "dart",
    "args": ["run", "dev_buddy_mcp"]
  }
}
```

## Verifying the Connection

You can test the HTTP bridge directly:

```bash
# Check if Flutter app's diagnostic server is running
curl http://localhost:8585/health

# Get a diagnostic snapshot
curl http://localhost:8585/snapshot

# Call a tool directly
curl -X POST http://localhost:8585/tool \
  -H "Content-Type: application/json" \
  -d '{"tool": "dev_buddy/diagnostics", "params": {}}'
```

## Security

- The diagnostic server **only binds to localhost** (127.0.0.1) — not accessible from network
- **Only runs in debug mode** — zero code in release builds
- All data is **PII-sanitized** before reaching AI (emails, tokens, keys are redacted)
- No secrets or user data leave the machine

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Flutter app not reachable" | Make sure `flutter run` is active and you see the `🔧` log message |
| Port already in use | Change `mcpServerPort` in your app and update `.mcp.json` |
| No events showing | Interact with your app — scroll, tap, navigate to generate diagnostics |
| MCP server not found | Ensure `dev_buddy_mcp` is in your dependencies or installed globally |

## Related Packages

- [dev_buddy](https://pub.dev/packages/dev_buddy) — Flutter diagnostics overlay
- [dev_buddy_engine](https://pub.dev/packages/dev_buddy_engine) — Pure Dart diagnostic engine
- [dev_buddy_devtools](https://pub.dev/packages/dev_buddy_devtools) — Flutter DevTools extension
