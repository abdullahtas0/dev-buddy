// packages/dev_buddy/lib/src/modules/memory/leak_heuristic.dart
import '../../core/severity.dart';
import 'memory_sampler.dart';

class MemoryEvaluation {
  final Severity severity;
  final String title;
  final String description;
  final List<String> suggestions;

  const MemoryEvaluation({
    required this.severity,
    required this.title,
    required this.description,
    required this.suggestions,
  });
}

/// Evaluates memory samples and detects potential leaks via heuristics.
class LeakHeuristic {
  final int warningThresholdMb;

  const LeakHeuristic({required this.warningThresholdMb});

  /// Returns null if memory looks healthy. Returns evaluation if issues detected.
  MemoryEvaluation? evaluate(MemorySampler sampler) {
    final currentMb = sampler.latestMb;
    final isGrowing = sampler.isMonotonicallyGrowing;

    // Critical: monotonic growth AND above threshold
    if (isGrowing && currentMb > warningThresholdMb) {
      return MemoryEvaluation(
        severity: Severity.critical,
        title: 'Possible Memory Leak',
        description:
            'RAM usage is ${currentMb}MB and growing steadily '
            '(+${sampler.growthRate}MB). Memory has not decreased across '
            '${sampler.samples.length} samples.',
        suggestions: [
          'Ensure all Controllers (TextEditingController, AnimationController, ScrollController) call dispose()',
          'Cancel StreamSubscriptions and Timers in dispose()',
          'Check for large images - consider using ResizeImage or cacheWidth/cacheHeight',
          'Run DevTools Memory tab for detailed heap analysis',
        ],
      );
    }

    // Warning: above threshold but not necessarily leaking
    if (currentMb > warningThresholdMb) {
      return MemoryEvaluation(
        severity: Severity.warning,
        title: 'High Memory Usage',
        description:
            'RAM usage is ${currentMb}MB (threshold: ${warningThresholdMb}MB).',
        suggestions: [
          'Check if large images or data are cached unnecessarily',
          'Call imageCache.clear() when navigating away from image-heavy screens',
          'Verify dispose() is called on all Controllers when leaving screens',
        ],
      );
    }

    return null; // healthy
  }
}
