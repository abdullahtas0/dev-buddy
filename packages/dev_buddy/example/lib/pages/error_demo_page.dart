// packages/dev_buddy/example/lib/pages/error_demo_page.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// Demonstrates error conditions that DevBuddy's ErrorTranslatorModule
/// can detect and translate:
/// - Column overflow (RenderFlex overflowed)
/// - setState called after dispose
class ErrorDemoPage extends StatelessWidget {
  const ErrorDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'This page demonstrates Flutter errors that DevBuddy '
              'translates into human-readable diagnostics with fix suggestions.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Overflow error
          const Text(
            'Overflow Error',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'The row below contains children that exceed the available '
            'width, causing a RenderFlex overflow error.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const _OverflowDemo(),

          const SizedBox(height: 32),

          // Section 2: setState after dispose
          const Text(
            'setState After Dispose',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below, then quickly navigate back. '
            'A delayed setState will fire after the widget is disposed.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const _SetStateAfterDisposeDemo(),
        ],
      ),
    );
  }
}

/// Intentionally creates a Row that overflows horizontally.
class _OverflowDemo extends StatelessWidget {
  const _OverflowDemo();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overflowing Row:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // Intentional: Row without Flexible/Expanded causes overflow
            Row(
              children: [
                Container(
                  width: 200,
                  height: 50,
                  color: Colors.red.shade200,
                  alignment: Alignment.center,
                  child: const Text('Box A (200px)'),
                ),
                Container(
                  width: 200,
                  height: 50,
                  color: Colors.orange.shade200,
                  alignment: Alignment.center,
                  child: const Text('Box B (200px)'),
                ),
                Container(
                  width: 200,
                  height: 50,
                  color: Colors.yellow.shade200,
                  alignment: Alignment.center,
                  child: const Text('Box C (200px)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Demonstrates setState called after dispose.
class _SetStateAfterDisposeDemo extends StatefulWidget {
  const _SetStateAfterDisposeDemo();

  @override
  State<_SetStateAfterDisposeDemo> createState() =>
      _SetStateAfterDisposeDemoState();
}

class _SetStateAfterDisposeDemoState extends State<_SetStateAfterDisposeDemo> {
  int _counter = 0;
  bool _timerStarted = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Counter: $_counter',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              _timerStarted
                  ? 'Timer started! Navigate back within 3 seconds to '
                      'trigger setState after dispose.'
                  : 'Tap the button to start a delayed setState.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _timerStarted
                  ? null
                  : () {
                      setState(() => _timerStarted = true);

                      // Intentional: no mounted check, will crash if disposed
                      Timer(const Duration(seconds: 3), () {
                        // ignore: invalid_use_of_protected_member
                        setState(() => _counter++);
                      });
                    },
              icon: const Icon(Icons.timer),
              label: Text(_timerStarted ? 'Timer running...' : 'Start Timer'),
            ),
          ],
        ),
      ),
    );
  }
}
