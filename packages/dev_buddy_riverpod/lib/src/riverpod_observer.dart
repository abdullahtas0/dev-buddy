import 'dart:convert';

import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod [ProviderObserver] that records state changes into DevBuddy's
/// [StateStore] for time-travel debugging.
///
/// ## Usage
/// ```dart
/// ProviderScope(
///   observers: [DevBuddyRiverpodObserver(stateStore: engine.stateStore)],
///   child: MyApp(),
/// )
/// ```
class DevBuddyRiverpodObserver extends ProviderObserver {
  final StateStore _stateStore;

  /// Optional serializer for custom state types.
  /// If null, uses `jsonEncode` with `toString()` fallback.
  final String Function(Object? value)? serializer;

  /// Maximum length for diff strings. Prevents StateStore budget bloat
  /// from large state objects. Default: 1024 characters.
  final int maxDiffLength;

  DevBuddyRiverpodObserver({
    required StateStore stateStore,
    this.serializer,
    this.maxDiffLength = 1024,
  }) : _stateStore = stateStore;

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    final source = _sourceId(provider);
    final newHash = newValue.hashCode;

    _stateStore.record(
      source: source,
      stateHashCode: newHash,
      serializedState: _serialize(newValue),
      serializedDiff: _computeDiff(previousValue, newValue),
      action: 'update',
    );
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    final source = _sourceId(provider);

    _stateStore.record(
      source: source,
      stateHashCode: value.hashCode,
      serializedState: _serialize(value),
      action: 'init',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    final source = _sourceId(provider);

    _stateStore.record(
      source: source,
      stateHashCode: 0, // Force record — disposed is always a change
      serializedState: 'null',
      action: 'dispose',
    );
  }

  String _sourceId(ProviderBase<Object?> provider) {
    final name = provider.name ?? provider.runtimeType.toString();
    return 'riverpod:$name';
  }

  String _serialize(Object? value) {
    if (serializer != null) return serializer!(value);
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  String? _computeDiff(Object? previous, Object? current) {
    if (previous == null) return null;
    try {
      final fromStr = _truncate(previous.toString());
      final toStr = _truncate(current.toString());
      return jsonEncode({'from': fromStr, 'to': toStr});
    } catch (_) {
      return '{"from": "${previous.runtimeType}", "to": "${current.runtimeType}"}';
    }
  }

  String _truncate(String value) {
    if (value.length <= maxDiffLength) return value;
    return '${value.substring(0, maxDiffLength)}... [TRUNCATED]';
  }
}
