# dev_buddy_devtools

Flutter DevTools extension for [DevBuddy](https://pub.dev/packages/dev_buddy). Exposes diagnostic data inside Flutter DevTools via service extensions.

## Installation

```yaml
dependencies:
  dev_buddy_engine: ^0.2.0
  dev_buddy_devtools: ^0.2.0
```

## Usage

```dart
import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:dev_buddy_devtools/dev_buddy_devtools.dart';

final engine = DevBuddyEngine();
engine.initialize();

// Register service extensions (call once, safe to call on hot restart)
DevBuddyServiceExtensions.register(engine);
```

## Service Extensions

| Extension | Purpose |
|-----------|---------|
| `ext.dev_buddy.snapshot` | Full diagnostic snapshot (JSON) |
| `ext.dev_buddy.events` | Paginated event history with module filter |
| `ext.dev_buddy.state` | State store contents for time-travel inspection |
| `ext.dev_buddy.clear` | Reset diagnostic state |

## Query Parameters

The `events` extension supports query parameters:

```
ext.dev_buddy.events?limit=20&module=network
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `limit` | `20` | Maximum events to return |
| `module` | `null` | Filter by module ID |

## Related Packages

- [dev_buddy](https://pub.dev/packages/dev_buddy) - Flutter diagnostics overlay
- [dev_buddy_engine](https://pub.dev/packages/dev_buddy_engine) - Pure Dart diagnostic engine
