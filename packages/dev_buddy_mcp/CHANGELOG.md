# Changelog

## 0.2.0

### Added
- `McpTools` — 9 AI-queryable diagnostic tools for Claude Code, Cursor, and Copilot
- `diagnostics()` — Compact snapshot of current diagnostic state
- `suggest()` — AI-friendly fix suggestions based on active issues
- `search_events()` — Filter events by module and severity
- `search_network()` — Query captured HTTP traffic
- `search_state()` — Browse state history for time-travel debugging
- `detail()` — Drill-down into specific events by index
- `performance()` — FPS and frame timing summary
- `memory()` — Memory usage and leak indicators
- `errors()` — Active error events with translated descriptions
- Data sanitization via `DataSanitizer` before returning data to AI consumers
- Summary-first API design to prevent LLM context overflow

## 0.1.0

### Added
- Initial MCP server scaffold
