// packages/dev_buddy/example/lib/pages/rebuild_demo_page.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// Demonstrates excessive widget rebuilds that DevBuddy's
/// RebuildTrackerModule can detect.
///
/// A widget calls setState every 100ms, causing the entire subtree
/// to rebuild at 10 Hz unnecessarily.
class RebuildDemoPage extends StatelessWidget {
  const RebuildDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rebuild Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'This page contains a widget that calls setState every '
              '100ms, causing excessive rebuilds. DevBuddy\'s Rebuild '
              'Tracker module flags widgets that rebuild too often.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          const _ExcessiveRebuilder(),
          const SizedBox(height: 16),
          const _RebuildExplanation(),
        ],
      ),
    );
  }
}

/// Widget that intentionally rebuilds every 100ms via setState.
class _ExcessiveRebuilder extends StatefulWidget {
  const _ExcessiveRebuilder();

  @override
  State<_ExcessiveRebuilder> createState() => _ExcessiveRebuilderState();
}

class _ExcessiveRebuilderState extends State<_ExcessiveRebuilder> {
  Timer? _timer;
  int _rebuildCount = 0;
  bool _running = false;

  void _start() {
    setState(() => _running = true);
    // Intentional: setState every 100ms is way too frequent
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() => _rebuildCount++);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    setState(() => _running = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Excessive Rebuilder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Intentional: entire subtree rebuilds unnecessarily
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _running
                    ? Colors.red.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _running ? Colors.red.shade200 : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$_rebuildCount',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: _running ? Colors.red : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'rebuilds',
                    style: TextStyle(
                      fontSize: 14,
                      color: _running
                          ? Colors.red.shade400
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _running ? null : _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _running ? _stop : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
            // Intentional: these children also rebuild every 100ms
            if (_running) ...[
              const SizedBox(height: 16),
              _UnnecessaryChild(value: _rebuildCount),
              _UnnecessaryChild(value: _rebuildCount * 2),
              _UnnecessaryChild(value: _rebuildCount * 3),
            ],
          ],
        ),
      ),
    );
  }
}

/// Child widget that rebuilds unnecessarily with its parent.
class _UnnecessaryChild extends StatelessWidget {
  final int value;
  const _UnnecessaryChild({required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.refresh, size: 14, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            'Child rebuild #$value',
            style: const TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}

class _RebuildExplanation extends StatelessWidget {
  const _RebuildExplanation();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.teal.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s wrong here?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '1. setState is called every 100ms (10 times/second)\n'
              '2. The entire widget subtree rebuilds each time\n'
              '3. Child widgets rebuild even though they could be const\n'
              '4. No ValueListenableBuilder or AnimationController is used\n\n'
              'DevBuddy\'s Rebuild Tracker detects this and suggests '
              'using ValueNotifier, extracting widgets, or using const.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
