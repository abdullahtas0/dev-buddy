// packages/dev_buddy/lib/src/modules/performance/performance_module.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/dev_buddy_config.dart';
import '../../core/dev_buddy_event.dart';
import '../../core/dev_buddy_module.dart';
import 'frame_analyzer.dart';
import 'jank_detector.dart';

/// Monitors frame rendering performance and detects UI jank.
///
/// Uses [SchedulerBinding.addTimingsCallback] to observe frame durations.
/// Emits [DevBuddyEvent]s when jank is detected, with human-readable
/// suggestions for fixing performance issues.
class PerformanceModule extends DevBuddyModule {
  @override
  String get id => 'performance';
  @override
  String get name => 'Performance';
  @override
  IconData get icon => Icons.speed;

  late FrameAnalyzer _analyzer;
  late JankDetector _jankDetector;
  late void Function(DevBuddyEvent) _onEvent;
  int _consecutiveJanks = 0;

  /// Current FPS value for the overlay pill. Exposed for the overlay widget.
  double get currentFps => _analyzer.averageFps;

  @override
  void initialize({
    required DevBuddyConfig config,
    required void Function(DevBuddyEvent) onEvent,
  }) {
    _analyzer = FrameAnalyzer(windowSize: 60);
    _jankDetector = JankDetector(thresholdMs: config.jankThresholdMs);
    _onEvent = onEvent;

    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    // Engine-level callback must never throw; guard the entire body.
    try {
      for (final timing in timings) {
        final duration = timing.totalSpan;
        _analyzer.addFrameDuration(duration);

        final result = _analyzer.analyzeFrame(
          duration: duration,
          thresholdMs: _jankDetector.thresholdMs,
        );

        if (result.isJank) {
          _consecutiveJanks++;
          final evaluation = _jankDetector.evaluate(
            durationMs: result.durationMs,
            consecutiveJanks: _consecutiveJanks,
          );

          _onEvent(
            DevBuddyEvent(
              module: id,
              severity: evaluation.severity,
              title: evaluation.title,
              description: evaluation.description,
              suggestions: evaluation.suggestions,
              metadata: {
                'frame_duration_ms': result.durationMs,
                'threshold_ms': result.thresholdMs,
                'consecutive_janks': _consecutiveJanks,
                'current_fps': _analyzer.averageFps,
              },
            ),
          );
        } else {
          _consecutiveJanks = 0;
        }
      }
    } catch (e) {
      debugPrint('DevBuddy: performance timing callback error: $e');
    }
  }

  @override
  Widget buildTab(BuildContext context, List<DevBuddyEvent> events) {
    if (events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
              SizedBox(height: 12),
              Text(
                'No performance issues detected',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _PerformanceEventTile(event: event);
      },
    );
  }
}

class _PerformanceEventTile extends StatelessWidget {
  final DevBuddyEvent event;
  const _PerformanceEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  event.severity.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              event.description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (event.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...event.suggestions.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('\u{1F4A1} ', style: TextStyle(fontSize: 11)),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
