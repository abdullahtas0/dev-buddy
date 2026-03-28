import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dev_buddy/dev_buddy.dart';

/// Shows the DevBuddyEngine snapshot — exactly what MCP tools
/// (Claude Code, Cursor) see when querying diagnostics.
class InspectorScreen extends StatefulWidget {
  const InspectorScreen({super.key});

  @override
  State<InspectorScreen> createState() => _InspectorScreenState();
}

class _InspectorScreenState extends State<InspectorScreen> {
  String _output = 'Tap a button to query the engine.';
  int _eventCount = 0;

  DevBuddyController? get _controller => DevBuddyScope.maybeOf(context);

  void _getSnapshot() {
    final ctrl = _controller;
    if (ctrl == null) {
      setState(() => _output = 'DevBuddy not available (release mode?)');
      return;
    }
    final snap = ctrl.engine.snapshot();
    setState(() {
      _output = const JsonEncoder.withIndent('  ').convert(snap);
      _eventCount = ctrl.engine.eventBus.length;
    });
  }

  void _getEvents() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final events = ctrl.engine.eventBus.history.take(10).map((e) => {
          'module': e.module,
          'severity': e.severity.name,
          'title': e.title,
          'time': e.timestamp.toIso8601String(),
        }).toList();
    setState(() {
      _output = const JsonEncoder.withIndent('  ').convert({'recent_events': events});
      _eventCount = ctrl.engine.eventBus.length;
    });
  }

  void _exportMarkdown() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final report = DevBuddyReport(
      events: ctrl.engine.eventBus.history,
      generatedAt: DateTime.now(),
      deviceInfo: {'platform': 'iOS Simulator', 'app': 'ShopBuddy'},
    );
    final md = MarkdownExporter().export(report);
    setState(() => _output = md);
  }

  void _clearAll() {
    _controller?.clearEvents();
    setState(() {
      _output = 'All events cleared.';
      _eventCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DevBuddy Inspector')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                const Text(
                  'This is what AI tools (Claude Code, Cursor) see\n'
                  'when they query DevBuddy via MCP.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text('Events: $_eventCount',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _getSnapshot,
                      icon: const Icon(Icons.camera, size: 18),
                      label: const Text('Snapshot'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _getEvents,
                      icon: const Icon(Icons.list, size: 18),
                      label: const Text('Events'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _exportMarkdown,
                      icon: const Icon(Icons.description, size: 18),
                      label: const Text('Markdown'),
                    ),
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1E1E1E),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFFD4D4D4),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
