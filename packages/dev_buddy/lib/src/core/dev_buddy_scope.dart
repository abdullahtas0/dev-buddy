// packages/dev_buddy/lib/src/core/dev_buddy_scope.dart
import 'package:flutter/widgets.dart';
import 'dev_buddy_controller.dart';

/// InheritedWidget that provides [DevBuddyController] to the widget tree.
///
/// Used internally by [DevBuddyOverlay]. Module tab widgets use
/// `DevBuddyScope.of(context)` to access the controller.
class DevBuddyScope extends InheritedWidget {
  final DevBuddyController controller;

  const DevBuddyScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// Returns the nearest [DevBuddyController] in the widget tree.
  /// Throws if no [DevBuddyScope] is found.
  static DevBuddyController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DevBuddyScope>();
    assert(scope != null, 'No DevBuddyScope found in widget tree');
    return scope!.controller;
  }

  /// Returns the nearest [DevBuddyController] or null.
  static DevBuddyController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DevBuddyScope>();
    return scope?.controller;
  }

  @override
  bool updateShouldNotify(DevBuddyScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
