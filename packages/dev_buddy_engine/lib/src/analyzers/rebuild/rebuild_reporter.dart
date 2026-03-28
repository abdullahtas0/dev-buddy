// packages/dev_buddy/lib/src/modules/rebuild_tracker/rebuild_reporter.dart
import '../../core/severity.dart';
import 'rebuild_counter.dart';

class RebuildEvaluation {
  final Severity severity;
  final String title;
  final String description;
  final List<String> suggestions;

  const RebuildEvaluation({
    required this.severity,
    required this.title,
    required this.description,
    required this.suggestions,
  });
}

/// Evaluates rebuild counts and produces human-readable diagnostics.
class RebuildReporter {
  final int warningThreshold;

  const RebuildReporter({required this.warningThreshold});

  /// Returns null if rebuild count is healthy. Returns evaluation if excessive.
  RebuildEvaluation? evaluate(RebuildCounter counter) {
    final frameCount = counter.frameRebuildCount;
    if (frameCount < warningThreshold) return null;

    final top = counter.topRebuilders(3);
    final topNames = top.map((e) => '${e.key}(${e.value}x)').join(', ');

    final severity = frameCount > warningThreshold * 3
        ? Severity.critical
        : Severity.warning;

    return RebuildEvaluation(
      severity: severity,
      title: severity == Severity.critical
          ? 'Excessive Widget Rebuilds'
          : 'High Widget Rebuild Count',
      description:
          '$frameCount widgets rebuilt in this frame. '
          'Top rebuilders: $topNames',
      suggestions: [
        'Use const constructors for widgets that never change: const MyWidget()',
        'Extract frequently-changing subtrees into separate widgets to limit rebuild scope',
        'Check if setState() is being called too broadly - it rebuilds the entire subtree',
        'Consider using ValueListenableBuilder or Selector to rebuild only what changed',
        if (severity == Severity.critical)
          'This many rebuilds will cause visible jank. Profile with DevTools Performance tab.',
      ],
    );
  }
}
