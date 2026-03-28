# dev_buddy_riverpod

Riverpod state tracking adapter for [DevBuddy](https://pub.dev/packages/dev_buddy). Records provider state changes for time-travel debugging via the DevBuddy engine's `StateStore`.

## Installation

```yaml
dependencies:
  dev_buddy_engine: ^0.2.0
  dev_buddy_riverpod: ^0.2.0
  flutter_riverpod: ^2.0.0
```

## Usage

```dart
import 'package:dev_buddy_riverpod/dev_buddy_riverpod.dart';
import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final engine = DevBuddyEngine();
engine.initialize();

// Add the observer to your ProviderScope
ProviderScope(
  observers: [
    DevBuddyRiverpodObserver(stateStore: engine.stateStore),
  ],
  child: MyApp(),
);
```

## What It Captures

| Event | Data |
|-------|------|
| `didAddProvider` | Provider name/type, initial state |
| `didUpdateProvider` | Previous state, new state, computed diff |
| `didDisposeProvider` | Provider name/type |

## Configuration

```dart
DevBuddyRiverpodObserver(
  stateStore: engine.stateStore,
  serializer: (value) => myCustomSerializer(value),  // Optional custom serializer
);
```

The serializer fallback chain: custom serializer -> `jsonEncode` -> `toString()`.

## Related Packages

- [dev_buddy](https://pub.dev/packages/dev_buddy) - Flutter diagnostics overlay
- [dev_buddy_engine](https://pub.dev/packages/dev_buddy_engine) - Pure Dart diagnostic engine
- [dev_buddy_bloc](https://pub.dev/packages/dev_buddy_bloc) - BLoC state tracking
