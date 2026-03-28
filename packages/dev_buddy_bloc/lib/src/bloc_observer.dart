import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dev_buddy_engine/dev_buddy_engine.dart';

/// BLoC [BlocObserver] that records state transitions into DevBuddy's
/// [StateStore] for time-travel debugging.
///
/// ## Usage
/// ```dart
/// Bloc.observer = DevBuddyBlocObserver(stateStore: engine.stateStore);
/// ```
class DevBuddyBlocObserver extends BlocObserver {
  final StateStore _stateStore;

  /// Optional serializer for custom state types.
  final String Function(Object? value)? serializer;

  /// Maximum length for diff strings. Prevents StateStore budget bloat
  /// from large state objects. Default: 1024 characters.
  final int maxDiffLength;

  DevBuddyBlocObserver({
    required StateStore stateStore,
    this.serializer,
    this.maxDiffLength = 1024,
  }) : _stateStore = stateStore;

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);

    final source = 'bloc:${bloc.runtimeType}';
    final newState = transition.nextState;
    final event = transition.event;

    _stateStore.record(
      source: source,
      stateHashCode: newState.hashCode,
      serializedState: _serialize(newState),
      serializedDiff: _computeDiff(transition.currentState, newState),
      action: event.runtimeType.toString(),
    );
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);

    // Only record Cubit changes (Bloc changes go through onTransition)
    if (bloc is! Bloc) {
      final source = 'cubit:${bloc.runtimeType}';

      _stateStore.record(
        source: source,
        stateHashCode: change.nextState.hashCode,
        serializedState: _serialize(change.nextState),
        serializedDiff: _computeDiff(change.currentState, change.nextState),
        action: 'change',
      );
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);

    final source = 'bloc:${bloc.runtimeType}';

    _stateStore.record(
      source: source,
      stateHashCode: error.hashCode,
      serializedState: _serialize({'error': error.toString()}),
      action: 'error',
    );
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
