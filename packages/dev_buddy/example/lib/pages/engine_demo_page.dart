import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dev_buddy/dev_buddy.dart';

/// Demonstrates the DevBuddyEngine snapshot API and event history.
/// Shows how MCP tools would query live diagnostics.
class EngineDemoPage extends StatefulWidget {
  const EngineDemoPage({super.key});

  @override
  State<EngineDemoPage> createState() => _EngineDemoPageState();
}

class _EngineDemoPageState extends State<EngineDemoPage> {
  String _snapshot = 'Tap "Get Snapshot" to query engine state';

  void _getSnapshot() {
    final controller = DevBuddyScope.maybeOf(context);
    if (controller == null) {
      setState(() => _snapshot = 'DevBuddy not available (release mode?)');
      return;
    }

    final snap = controller.engine.snapshot();
    final encoder = const JsonEncoder.withIndent('  ');
    setState(() => _snapshot = encoder.convert(snap));
  }

  void _clearEvents() {
    DevBuddyScope.maybeOf(context)?.clearEvents();
    setState(() => _snapshot = 'Events cleared');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Engine Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This page demonstrates the DevBuddyEngine API.\n'
              'MCP tools (Claude Code / Cursor) call these same methods.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _getSnapshot,
                    icon: const Icon(Icons.camera),
                    label: const Text('Get Snapshot'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _clearEvents,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _snapshot,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
