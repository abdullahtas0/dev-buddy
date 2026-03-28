import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Demonstrates triggering cross-signal correlation events.
/// Intentionally creates compound scenarios that the CorrelationEngine detects.
class CorrelationDemoPage extends StatefulWidget {
  const CorrelationDemoPage({super.key});

  @override
  State<CorrelationDemoPage> createState() => _CorrelationDemoPageState();
}

class _CorrelationDemoPageState extends State<CorrelationDemoPage> {
  String _status = 'Tap a scenario to trigger compound diagnostics';

  void _triggerJankPlusRebuilds() {
    setState(() => _status = 'Triggering jank + excessive rebuilds...');

    // Trigger heavy rebuilds that cause jank
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Force expensive computation during build
      final list = List.generate(10000, (i) => Random().nextDouble());
      list.sort();
      setState(() {
        _status = 'Rebuilding with heavy computation... '
            '(sum: ${list.take(5).reduce((a, b) => a + b).toStringAsFixed(2)})';
      });

      // Stop after 3 seconds
      if (timer.tick > 60) {
        timer.cancel();
        if (mounted) {
          setState(() => _status = 'Done! Check DevBuddy panel for correlation insights.');
        }
      }
    });
  }

  void _triggerMemoryGrowth() {
    setState(() => _status = 'Allocating memory without disposing...');

    final leakedControllers = <TextEditingController>[];

    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        for (final c in leakedControllers) {
          c.dispose();
        }
        return;
      }

      // Leak controllers (they won't be disposed)
      for (var i = 0; i < 10; i++) {
        leakedControllers.add(TextEditingController(text: 'leak $i' * 100));
      }

      setState(() {
        _status = 'Leaked ${leakedControllers.length} controllers. '
            'Navigate away to trigger memory+navigation correlation.';
      });

      if (timer.tick > 25) {
        timer.cancel();
        if (mounted) {
          setState(() => _status = 'Done! Navigate back and forth to trigger correlation.');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Correlation Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DevBuddy correlates signals across modules.\n'
              'When jank + rebuilds happen together, or memory grows '
              'during navigation, compound insights appear in the panel.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _triggerJankPlusRebuilds,
              icon: const Icon(Icons.speed),
              label: const Text('Jank + Rebuilds'),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _triggerMemoryGrowth,
              icon: const Icon(Icons.memory),
              label: const Text('Memory Growth'),
              style: FilledButton.styleFrom(backgroundColor: Colors.purple),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
