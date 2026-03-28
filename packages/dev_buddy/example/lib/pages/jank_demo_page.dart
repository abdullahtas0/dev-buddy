// packages/dev_buddy/example/lib/pages/jank_demo_page.dart
import 'dart:math';
import 'package:flutter/material.dart';

/// Demonstrates performance jank by rendering 1000 heavy list items
/// using a plain ListView (NOT ListView.builder), each with expensive
/// BoxShadow and Opacity widgets.
///
/// DevBuddy's PerformanceModule should detect frame drops and suggest
/// using ListView.builder and avoiding Opacity/BoxShadow.
class JankDemoPage extends StatelessWidget {
  const JankDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Intentional: building all 1000 items at once (no lazy loading).
    final items = List.generate(1000, (i) => _HeavyItem(index: i));

    return Scaffold(
      appBar: AppBar(title: const Text('Jank Demo')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            width: double.infinity,
            child: const Text(
              'This page uses a plain ListView (not .builder) with 1000 '
              'items. Each item has BoxShadow and Opacity widgets, which '
              'are expensive to render. Scroll to trigger jank detection.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          // Intentional: plain ListView, not ListView.builder
          Expanded(
            child: ListView(
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeavyItem extends StatelessWidget {
  final int index;
  const _HeavyItem({required this.index});

  @override
  Widget build(BuildContext context) {
    final random = Random(index);
    final hue = (random.nextDouble() * 360).roundToDouble();

    // Intentional: Opacity widget forces saveLayer (expensive)
    return Opacity(
      opacity: 0.9,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HSLColor.fromAHSL(1, hue, 0.6, 0.95).toColor(),
          borderRadius: BorderRadius.circular(12),
          // Intentional: BoxShadow is expensive, especially with blur
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: HSLColor.fromAHSL(0.2, hue, 0.8, 0.5).toColor(),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Intentional: another Opacity for extra cost
            Opacity(
              opacity: 0.7,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HSLColor.fromAHSL(1, hue, 0.7, 0.6).toColor(),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heavy Item #${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This item has multiple BoxShadows and Opacity widgets '
                    'that force expensive saveLayer operations.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
