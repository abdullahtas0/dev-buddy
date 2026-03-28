// packages/dev_buddy/lib/src/modules/rebuild_tracker/rebuild_tracker_module.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/dev_buddy_config.dart';
import '../../core/dev_buddy_event.dart';
import '../../core/dev_buddy_module.dart';
import 'rebuild_counter.dart';
import 'rebuild_reporter.dart';

/// Tracks widget rebuilds per frame and flags excessive rebuilds.
///
/// Uses Flutter's debug rebuild tracking (`debugOnRebuildDirtyWidget`)
/// to count how many widgets rebuild each frame.
/// Only works in debug mode (the callback is stripped in release).
class RebuildTrackerModule extends DevBuddyModule {
  @override
  String get id => 'rebuilds';
  @override
  String get name => 'Rebuilds';
  @override
  IconData get icon => Icons.refresh;

  late RebuildCounter _counter;
  late RebuildReporter _reporter;
  late void Function(DevBuddyEvent) _onEvent;
  bool _frameCallbackScheduled = false;
  bool _disposed = false;

  @override
  void initialize({
    required DevBuddyConfig config,
    required void Function(DevBuddyEvent event) onEvent,
  }) {
    _disposed = false;
    _frameCallbackScheduled = false;
    _counter = RebuildCounter();
    _reporter = RebuildReporter(
      warningThreshold: config.rebuildWarningThreshold,
    );
    _onEvent = onEvent;

    // Hook into Flutter's debug rebuild callback
    debugOnRebuildDirtyWidget = _onRebuild;
  }

  @override
  void dispose() {
    _disposed = true;
    debugOnRebuildDirtyWidget = null;
    _counter.resetAll();
  }

  void _onRebuild(Element element, bool builtOnce) {
    // Use Type directly as Map key (fast), not .toString() (slow).
    // .toString() is only called in UI display, not hot path.
    _counter.recordRebuild(element.widget.runtimeType);

    // Schedule exactly one post-frame callback per frame, regardless of
    // how many widgets rebuild. Without this guard, 100 rebuilds would
    // queue 100 redundant callbacks.
    if (!_frameCallbackScheduled) {
      _frameCallbackScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _frameCallbackScheduled = false;
        if (_disposed) return;
        final evaluation = _reporter.evaluate(_counter);
        if (evaluation != null) {
          _onEvent(
            DevBuddyEvent(
              module: id,
              severity: evaluation.severity,
              title: evaluation.title,
              description: evaluation.description,
              suggestions: evaluation.suggestions,
              metadata: {
                'frame_rebuild_count': _counter.frameRebuildCount,
                'top_rebuilders': _counter
                    .topRebuildersAsString(5)
                    .map((e) => {'widget': e.key, 'count': e.value})
                    .toList(),
              },
            ),
          );
        }
        _counter.resetFrame();
      });
    }
  }

  @override
  Widget buildTab(BuildContext context, List<DevBuddyEvent> events) {
    final top = _counter.topRebuildersAsString(10);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Top Rebuilders',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (top.isEmpty)
            const Center(
              child: Text(
                'No rebuild data yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...top.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: entry.value > 50
                            ? Colors.red.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${entry.value}x',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: entry.value > 50
                              ? Colors.red
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    dense: true,
                    leading: Text(event.severity.emoji),
                    title: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      event.description,
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
