// packages/dev_buddy/lib/src/modules/performance/jank_detector.dart
import '../../core/severity.dart';

/// Result of jank evaluation with severity and human-readable suggestions.
class JankEvaluation {
  final Severity severity;
  final String title;
  final String description;
  final List<String> suggestions;

  const JankEvaluation({
    required this.severity,
    required this.title,
    required this.description,
    required this.suggestions,
  });
}

/// Evaluates frame timing data and produces human-readable diagnostics.
///
/// Pure logic - no Flutter dependency. The [PerformanceModule] feeds
/// frame data into this and emits events from the results.
class JankDetector {
  final double thresholdMs;

  const JankDetector({required this.thresholdMs});

  /// Evaluates a jank occurrence and returns severity + suggestions.
  JankEvaluation evaluate({
    required double durationMs,
    required int consecutiveJanks,
  }) {
    final severity = _computeSeverity(durationMs, consecutiveJanks);
    final suggestions = _buildSuggestions(durationMs, consecutiveJanks);

    return JankEvaluation(
      severity: severity,
      title: severity == Severity.critical
          ? 'Severe UI Jank'
          : 'UI Jank Detected',
      description:
          'Frame took ${durationMs.toStringAsFixed(1)}ms '
          '(threshold: ${thresholdMs.toStringAsFixed(1)}ms). '
          '${consecutiveJanks > 1 ? '$consecutiveJanks consecutive slow frames.' : ''}',
      suggestions: suggestions,
    );
  }

  Severity _computeSeverity(double durationMs, int consecutiveJanks) {
    if (consecutiveJanks >= 5 || durationMs > 50) return Severity.critical;
    if (durationMs > thresholdMs) return Severity.warning;
    return Severity.info;
  }

  List<String> _buildSuggestions(double durationMs, int consecutiveJanks) {
    final suggestions = <String>[];

    suggestions.add(
      'If this screen has a scrollable list, use ListView.builder instead of ListView with children.',
    );

    suggestions.add(
      'Reduce visual effects: BoxShadow, Opacity widget, and ClipRRect with complex paths are expensive.',
    );

    if (durationMs > 33) {
      suggestions.add(
        'Consider extracting heavy build logic into smaller widgets to isolate rebuilds.',
      );
    }

    if (durationMs > 50) {
      suggestions.add(
        'The build method may be doing too much work. Move computation out of build() into initState() or a state management solution.',
      );
    }

    if (consecutiveJanks >= 3) {
      suggestions.add(
        'Multiple consecutive janks suggest a systemic issue. Check if an animation or timer is triggering excessive rebuilds.',
      );
    }

    return suggestions;
  }
}
