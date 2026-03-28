// packages/dev_buddy/example/lib/pages/memory_demo_page.dart
import 'package:flutter/material.dart';

/// Demonstrates memory leak patterns that DevBuddy's MemoryModule can detect.
///
/// Creates TextEditingControllers in a loop without ever disposing them,
/// causing RSS memory to grow over time.
class MemoryDemoPage extends StatefulWidget {
  const MemoryDemoPage({super.key});

  @override
  State<MemoryDemoPage> createState() => _MemoryDemoPageState();
}

class _MemoryDemoPageState extends State<MemoryDemoPage> {
  // Intentional: storing controllers without disposing them
  final List<TextEditingController> _leakedControllers = [];
  final List<List<int>> _leakedBuffers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'This page creates objects without disposing them, '
              'causing memory to grow. DevBuddy\'s Memory module '
              'monitors RSS and flags monotonic growth.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),

          // Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Leak Status',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Leaked controllers: ${_leakedControllers.length}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leaked buffers: ${_leakedBuffers.length} '
                    '(~${_leakedBuffers.length} MB)',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Leak controllers button
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: _leakControllers,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.text_fields,
                          color: Colors.purple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Leak 100 TextEditingControllers',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              )),
                          SizedBox(height: 4),
                          Text(
                            'Creates 100 TextEditingControllers that are '
                            'never disposed. Each holds listeners and state.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Leak buffers button
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: _leakMemoryBuffers,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storage,
                          color: Colors.deepPurple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Leak 1 MB Buffer',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              )),
                          SizedBox(height: 4),
                          Text(
                            'Allocates a 1 MB List<int> that is never released. '
                            'Tap multiple times to grow RSS.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _leakControllers() {
    // Intentional: create controllers without disposing
    for (var i = 0; i < 100; i++) {
      final controller = TextEditingController(text: 'Leaked #$i');
      // Add a listener to prevent GC from collecting it
      controller.addListener(() {});
      _leakedControllers.add(controller);
    }
    setState(() {});
  }

  void _leakMemoryBuffers() {
    // Intentional: allocate ~1 MB that is never freed
    final buffer = List<int>.filled(1024 * 1024, 42);
    _leakedBuffers.add(buffer);
    setState(() {});
  }

  // Intentional: no dispose override - controllers are never cleaned up
}
