// packages/dev_buddy/lib/src/navigation/screen_aware_observer.dart
import 'dart:collection';

import 'package:flutter/widgets.dart';

/// A record of a screen transition, capturing the screen name and timestamp.
class ScreenTransitionRecord {
  /// The name of the screen from [RouteSettings.name].
  final String screenName;

  /// When the transition occurred.
  final DateTime timestamp;

  /// Creates a screen transition record.
  const ScreenTransitionRecord({
    required this.screenName,
    required this.timestamp,
  });

  @override
  String toString() =>
      'ScreenTransitionRecord(screenName: $screenName, timestamp: $timestamp)';
}

/// A [NavigatorObserver] that tracks screen transitions and associates metrics
/// per screen.
///
/// Attach this observer to your [Navigator] or [MaterialApp.navigatorObservers]
/// to automatically track which screen the user is on:
///
/// ```dart
/// final observer = DevBuddyNavigatorObserverImpl();
///
/// MaterialApp(
///   navigatorObservers: [observer],
///   // ...
/// );
/// ```
///
/// Access the current screen name via [currentScreen] and the full transition
/// history via [screenHistory].
class DevBuddyNavigatorObserverImpl extends NavigatorObserver {
  final List<String> _routeStack = [];
  final List<ScreenTransitionRecord> _history = [];

  /// The name of the currently visible screen, or `null` if the stack is empty
  /// or the current route has no name.
  String? get currentScreen =>
      _routeStack.isEmpty ? null : _routeStack.last;

  /// An unmodifiable list of all screen transitions recorded so far,
  /// in chronological order.
  List<ScreenTransitionRecord> get screenHistory =>
      UnmodifiableListView(_history);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final name = route.settings.name;
    if (name == null) return;

    _routeStack.add(name);
    _history.add(ScreenTransitionRecord(
      screenName: name,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final name = route.settings.name;
    if (name == null) return;

    // Remove the last occurrence of this route name from the stack.
    final index = _routeStack.lastIndexOf(name);
    if (index != -1) {
      _routeStack.removeAt(index);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    // Remove old route from stack.
    final oldName = oldRoute?.settings.name;
    if (oldName != null) {
      final index = _routeStack.lastIndexOf(oldName);
      if (index != -1) {
        _routeStack.removeAt(index);
      }
    }

    // Add new route to stack and history.
    final newName = newRoute?.settings.name;
    if (newName != null) {
      _routeStack.add(newName);
      _history.add(ScreenTransitionRecord(
        screenName: newName,
        timestamp: DateTime.now(),
      ));
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    final name = route.settings.name;
    if (name == null) return;

    final index = _routeStack.lastIndexOf(name);
    if (index != -1) {
      _routeStack.removeAt(index);
    }
  }
}
