// packages/dev_buddy/lib/src/ui/overlay/dev_buddy_overlay.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/dev_buddy_config.dart';
import '../../core/dev_buddy_controller.dart';
import '../../core/dev_buddy_module.dart';
import '../../core/dev_buddy_scope.dart';
import '../../core/diagnostic_server.dart';
import '../../modules/performance/performance_module.dart';
import '../panel/dev_buddy_panel.dart';
import 'draggable_pill.dart';

/// The main overlay widget. Wraps the app's widget tree and displays
/// a floating diagnostic pill + expandable panel.
class DevBuddyOverlayImpl extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final List<DevBuddyModule> modules;
  final DevBuddyConfig? config;

  /// Enable the MCP diagnostic server on localhost.
  /// When true, starts an HTTP server that Claude Code can query.
  /// Default port: 8585. Only active in debug mode.
  final bool enableMcpServer;

  /// Port for the MCP diagnostic server. Default: 8585.
  final int mcpServerPort;

  const DevBuddyOverlayImpl({
    super.key,
    required this.child,
    this.enabled = true,
    this.modules = const [],
    this.config,
    this.enableMcpServer = true,
    this.mcpServerPort = 8585,
  });

  @override
  State<DevBuddyOverlayImpl> createState() => _DevBuddyOverlayImplState();
}

class _DevBuddyOverlayImplState extends State<DevBuddyOverlayImpl> {
  late DevBuddyController _controller;
  final ValueNotifier<double> _fps = ValueNotifier(0);
  bool _panelOpen = false;
  Timer? _fpsTimer;
  PerformanceModule? _perfModule;
  DevBuddyDiagnosticServer? _diagnosticServer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _controller = DevBuddyController(
        modules: widget.modules,
        config: widget.config ?? const DevBuddyConfig(),
      );
      _controller.initialize();

      // Find PerformanceModule for FPS reading
      for (final module in widget.modules) {
        if (module is PerformanceModule) {
          _perfModule = module;
          break;
        }
      }

      // Update FPS pill every 300ms (smooth, not every frame)
      _fpsTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        if (_perfModule != null) {
          _fps.value = _perfModule!.currentFps;
        }
      });

      // Start MCP diagnostic server for Claude Code integration
      if (widget.enableMcpServer) {
        _diagnosticServer = DevBuddyDiagnosticServer(
          engine: _controller.engine,
          port: widget.mcpServerPort,
        );
        _diagnosticServer!.start();
      }
    }
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
    _diagnosticServer?.stop();
    if (widget.enabled) {
      _controller.dispose();
    }
    _fps.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() {
      _panelOpen = !_panelOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return DevBuddyScope(
      controller: _controller,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            widget.child,
            DraggablePill(
              fps: _fps,
              severity: _controller.overallSeverity,
              onTap: _togglePanel,
            ),
            if (_panelOpen)
              DevBuddyPanel(controller: _controller, onClose: _togglePanel),
          ],
        ),
      ),
    );
  }
}
