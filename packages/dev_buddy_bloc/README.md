# dev_buddy_bloc

BLoC/Cubit state tracking adapter for [DevBuddy](https://pub.dev/packages/dev_buddy). Records state transitions for time-travel debugging via the DevBuddy engine's `StateStore`.

## Installation

```yaml
dependencies:
  dev_buddy_engine: ^0.2.0
  dev_buddy_bloc: ^0.2.0
  bloc: ^8.0.0
```

## Usage

```dart
import 'package:dev_buddy_bloc/dev_buddy_bloc.dart';
import 'package:dev_buddy_engine/dev_buddy_engine.dart';

final engine = DevBuddyEngine();
engine.initialize();

// Register the observer globally
Bloc.observer = DevBuddyBlocObserver(
  stateStore: engine.stateStore,
);
```

## What It Captures

| Event | Source | Data |
|-------|--------|------|
| `onTransition` | BLoC | Event type, previous state, next state |
| `onChange` | Cubit | Previous state, next state |
| `onError` | Both | Exception details, stack trace |

## Configuration

```dart
DevBuddyBlocObserver(
  stateStore: engine.stateStore,
  serializer: (value) => myCustomSerializer(value),  // Optional custom serializer
);
```

The serializer fallback chain: custom serializer -> `jsonEncode` -> `toString()`.

## Related Packages

- [dev_buddy](https://pub.dev/packages/dev_buddy) - Flutter diagnostics overlay
- [dev_buddy_engine](https://pub.dev/packages/dev_buddy_engine) - Pure Dart diagnostic engine
- [dev_buddy_riverpod](https://pub.dev/packages/dev_buddy_riverpod) - Riverpod state tracking
