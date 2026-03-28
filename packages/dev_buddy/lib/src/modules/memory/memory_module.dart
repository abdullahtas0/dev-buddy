// packages/dev_buddy/lib/src/modules/memory/memory_module.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/dev_buddy_config.dart';
import '../../core/dev_buddy_event.dart';
import '../../core/dev_buddy_module.dart';
import 'leak_heuristic.dart';
import 'memory_sampler.dart';

/// Monitors app memory usage and detects potential memory leaks.
///
/// Samples `ProcessInfo.currentRss` every 5 seconds and uses
/// [LeakHeuristic] to flag monotonic growth or high usage.
///
/// **Note:** RSS includes Native + Dart + Skia/Impeller memory.
/// It is a coarse metric — the OS may delay GC, causing false positives.
/// For precise Dart heap leak detection, use DevTools Memory tab.
/// V2 will integrate `dart:developer` Service for Dart-specific heap data.
class MemoryModule extends DevBuddyModule {
  @override
  String get id => 'memory';
  @override
  String get name => 'Memory';
  @override
  IconData get icon => Icons.memory;

  late MemorySampler _sampler;
  late LeakHeuristic _heuristic;
  late void Function(DevBuddyEvent) _onEvent;
  Timer? _timer;

  @override
  void initialize({
    required DevBuddyConfig config,
    required void Function(DevBuddyEvent event) onEvent,
  }) {
    _sampler = MemorySampler(maxSamples: 60);
    _heuristic = LeakHeuristic(
      warningThresholdMb: config.memoryWarningThresholdMb,
    );
    _onEvent = onEvent;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _sample());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sampler.reset();
  }

  void _sample() {
    final rssBytes = ProcessInfo.currentRss;
    final rssMb = (rssBytes / (1024 * 1024)).round();
    _sampler.addSample(rssMb);

    final evaluation = _heuristic.evaluate(_sampler);
    if (evaluation != null) {
      _onEvent(
        DevBuddyEvent(
          module: id,
          severity: evaluation.severity,
          title: evaluation.title,
          description: evaluation.description,
          suggestions: evaluation.suggestions,
          metadata: {
            'current_mb': rssMb,
            'growth_rate': _sampler.growthRate,
            'sample_count': _sampler.samples.length,
          },
        ),
      );
    }
  }

  @override
  Widget buildTab(BuildContext context, List<DevBuddyEvent> events) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_sampler.latestMb} MB',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Current RSS memory usage',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: Text(event.severity.emoji),
                      title: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        event.description,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  'Memory usage is healthy',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
