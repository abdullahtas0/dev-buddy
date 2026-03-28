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

  DevBuddyBlocObserver({
    required StateStore stateStore,
    this.serializer,
  }) : _stateStore = stateStore;

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
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
      return jsonEncode({
        'from': previous.toString(),
        'to': current.toString(),
      });
    } catch (_) {
      return '{"from": "${previous.runtimeType}", "to": "${current.runtimeType}"}';
    }
  }
}
