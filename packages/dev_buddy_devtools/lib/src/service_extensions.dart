import 'dart:convert';
import 'dart:developer';

import 'package:dev_buddy_engine/dev_buddy_engine.dart';

/// Registers `ext.dev_buddy.*` service extensions with the Dart VM.
///
/// These extensions allow DevTools and external tools to query
/// DevBuddy diagnostics via the VM Service Protocol.
///
/// Call once during engine initialization:
/// ```dart
/// DevBuddyServiceExtensions.register(engine);
/// ```
class DevBuddyServiceExtensions {
  static bool _registered = false;

  /// Register all DevBuddy service extensions.
  static void register(DevBuddyEngine engine) {
    if (_registered) return;
    _registered = true;

    registerExtension('ext.dev_buddy.snapshot', (method, params) async {
      return ServiceExtensionResponse.result(
        jsonEncode(engine.snapshot()),
      );
    });

    registerExtension('ext.dev_buddy.events', (method, params) async {
      final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
      final module = params['module'];

      var events = engine.eventBus.history;
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

    registerExtension('ext.dev_buddy.state', (method, params) async {
      final limit = int.tryParse(params['limit'] ?? '10') ?? 10;
      final source = params['source'];

      var snapshots = engine.stateStore.history;
      if (source != null) {
        snapshots = snapshots.where((s) => s.source.contains(source)).toList();
      }

      return ServiceExtensionResponse.result(
        jsonEncode({
          'total': snapshots.length,
          'budget_usage': engine.stateStore.budgetUsagePercent,
          'snapshots': snapshots.take(limit).map((s) => s.toJson()).toList(),
        }),
      );
    });

    registerExtension('ext.dev_buddy.clear', (method, params) async {
      engine.clearEvents();
      engine.stateStore.clear();
      return ServiceExtensionResponse.result(jsonEncode({'cleared': true}));
    });
  }
}
