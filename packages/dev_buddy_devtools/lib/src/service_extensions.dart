import 'dart:convert';
import 'dart:developer';

import 'package:dev_buddy_engine/dev_buddy_engine.dart';

/// Registers `ext.dev_buddy.*` service extensions with the Dart VM.
///
/// Service extensions can only be registered once per isolate in Dart.
/// If the engine is recreated (e.g., hot restart), the extensions
/// automatically point to the latest engine via the mutable reference.
///
/// Call once during engine initialization:
/// ```dart
/// DevBuddyServiceExtensions.register(engine);
/// ```
class DevBuddyServiceExtensions {
  static bool _registered = false;
  static DevBuddyEngine? _engine;

  /// Register all DevBuddy service extensions.
  /// Safe to call multiple times — subsequent calls update the engine reference.
  static void register(DevBuddyEngine engine) {
    _engine = engine;

    if (_registered) return; // Extensions already registered, just update ref
    _registered = true;

    registerExtension('ext.dev_buddy.snapshot', (method, params) async {
      return _safeHandle(() {
        return ServiceExtensionResponse.result(jsonEncode(_engine!.snapshot()));
      });
    });

    registerExtension('ext.dev_buddy.events', (method, params) async {
      return _safeHandle(() {
        final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
        final module = params['module'];

        var events = _engine!.eventBus.history;
        if (module != null) {
          events = events.where((e) => e.module == module).toList();
        }

        return ServiceExtensionResponse.result(
          jsonEncode({
            'total': events.length,
            'events': events.take(limit).map((e) => e.toJson()).toList(),
          }),
        );
      });
    });

    registerExtension('ext.dev_buddy.state', (method, params) async {
      return _safeHandle(() {
        final limit = int.tryParse(params['limit'] ?? '10') ?? 10;
        final source = params['source'];

        var snapshots = _engine!.stateStore.history;
        if (source != null) {
          snapshots = snapshots
              .where((s) => s.source.contains(source))
              .toList();
        }

        return ServiceExtensionResponse.result(
          jsonEncode({
            'total': snapshots.length,
            'budget_usage': _engine!.stateStore.budgetUsagePercent,
            'snapshots': snapshots.take(limit).map((s) => s.toJson()).toList(),
          }),
        );
      });
    });

    registerExtension('ext.dev_buddy.clear', (method, params) async {
      return _safeHandle(() {
        _engine!.clearEvents();
        _engine!.stateStore.clear();
        return ServiceExtensionResponse.result(jsonEncode({'cleared': true}));
      });
    });
  }

  /// Wraps a service extension handler with error safety.
  ///
  /// Catches all exceptions (including [jsonEncode] failures) and returns
  /// a structured error response instead of crashing the extension.
  static ServiceExtensionResponse _safeHandle(
    ServiceExtensionResponse Function() handler,
  ) {
    if (_engine == null) {
      return ServiceExtensionResponse.error(-1, 'Engine not available');
    }
    try {
      return handler();
    } catch (e, stack) {
      return ServiceExtensionResponse.error(
        -1,
        jsonEncode({
          'error': e.toString(),
          'stack': stack.toString().split('\n').take(5).join('\n'),
        }),
      );
    }
  }
}
