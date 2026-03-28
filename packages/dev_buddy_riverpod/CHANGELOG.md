# Changelog

## 0.2.0

### Added
- `DevBuddyRiverpodObserver` — Riverpod `ProviderObserver` for state time-travel
- Records `didAddProvider`, `didUpdateProvider`, `didDisposeProvider` events
- Custom serializer support for complex state objects
- Automatic diff computation between state changes
- Fallback serialization chain: custom → jsonEncode → toString

## 0.1.0

### Added
- Initial Riverpod adapter implementation
