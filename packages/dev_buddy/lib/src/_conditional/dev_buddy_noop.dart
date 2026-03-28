// packages/dev_buddy/lib/src/_conditional/dev_buddy_noop.dart
//
// Release build: all implementations are no-ops with zero overhead.
// Tree-shaking removes all DevBuddy code from the final binary.

import 'package:flutter/widgets.dart';

/// No-op overlay for release builds. Zero overhead — just returns child.
class DevBuddyOverlayImpl extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final List<dynamic> modules;
  final dynamic config;

  const DevBuddyOverlayImpl({
    super.key,
    required this.child,
    this.enabled = true,
    this.modules = const [],
    this.config,
  });

  @override
  Widget build(BuildContext context) => child;
}

/// No-op NavigatorObserver for release builds.
class DevBuddyNavigatorObserverImpl extends NavigatorObserver {}

/// No-op report exporter for release builds.
class DevBuddyExporterImpl {
  const DevBuddyExporterImpl({dynamic report});

  Map<String, dynamic> exportJson() => const {};
  String exportText() => '';
}
