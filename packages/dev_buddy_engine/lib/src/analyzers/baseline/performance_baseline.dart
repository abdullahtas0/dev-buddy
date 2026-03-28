import '../../core/severity.dart';

/// Captured performance baseline for a single screen.
class PerformanceBaseline {
  final String screenName;
  final String? buildVersion;
  final double medianFps;
  final double p95FrameDurationMs;
  final int medianRebuildCount;
  final int medianMemoryMb;
  final DateTime recordedAt;
  final int sampleCount;

  const PerformanceBaseline({
    required this.screenName,
    this.buildVersion,
    required this.medianFps,
    required this.p95FrameDurationMs,
    required this.medianRebuildCount,
    required this.medianMemoryMb,
    required this.recordedAt,
    this.sampleCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'screen': screenName,
        if (buildVersion != null) 'build': buildVersion,
        'median_fps': medianFps,
        'p95_frame_ms': p95FrameDurationMs,
        'median_rebuilds': medianRebuildCount,
        'median_memory_mb': medianMemoryMb,
        'recorded_at': recordedAt.toIso8601String(),
        'samples': sampleCount,
      };

  factory PerformanceBaseline.fromJson(Map<String, dynamic> json) =>
      PerformanceBaseline(
        screenName: json['screen'] as String,
        buildVersion: json['build'] as String?,
        medianFps: (json['median_fps'] as num).toDouble(),
        p95FrameDurationMs: (json['p95_frame_ms'] as num).toDouble(),
        medianRebuildCount: json['median_rebuilds'] as int,
        medianMemoryMb: json['median_memory_mb'] as int,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        sampleCount: json['samples'] as int? ?? 1,
      );
}

/// Result of comparing current metrics against a baseline.
class RegressionReport {
  final String screenName;
  final Severity severity;
  final String title;
  final String description;
  final List<String> suggestions;
  final PerformanceBaseline baseline;
  final PerformanceBaseline current;

  const RegressionReport({
    required this.screenName,
    required this.severity,
    required this.title,
    required this.description,
    required this.suggestions,
    required this.baseline,
    required this.current,
  });
}

/// Detects performance regressions by comparing current metrics to baselines.
class RegressionDetector {
  /// FPS drop percentage to trigger warning.
  final double fpsTolerancePercent;

  /// Frame duration increase percentage to trigger warning.
  final double frameDurationTolerancePercent;

  /// Memory increase in MB to trigger warning.
  final int memoryToleranceMb;

  const RegressionDetector({
    this.fpsTolerancePercent = 10.0,
    this.frameDurationTolerancePercent = 20.0,
    this.memoryToleranceMb = 50,
  });

  /// Compare current metrics against baseline.
  /// Returns null if within tolerance, or a [RegressionReport] if degraded.
  RegressionReport? compare(PerformanceBaseline baseline, PerformanceBaseline current) {
    final regressions = <String>[];
    final suggestions = <String>[];

    // FPS regression
    if (baseline.medianFps > 0) {
      final fpsDrop = ((baseline.medianFps - current.medianFps) / baseline.medianFps) * 100;
      if (fpsDrop > fpsTolerancePercent) {
        regressions.add('FPS dropped ${fpsDrop.toStringAsFixed(1)}% '
            '(${baseline.medianFps.round()} → ${current.medianFps.round()})');
        suggestions.add('Check recent code changes for expensive build methods');
      }
    }

    // Frame duration regression
    if (baseline.p95FrameDurationMs > 0) {
      final increase = ((current.p95FrameDurationMs - baseline.p95FrameDurationMs) /
              baseline.p95FrameDurationMs) * 100;
      if (increase > frameDurationTolerancePercent) {
        regressions.add('P95 frame time increased ${increase.toStringAsFixed(1)}% '
            '(${baseline.p95FrameDurationMs.toStringAsFixed(1)}ms → '
            '${current.p95FrameDurationMs.toStringAsFixed(1)}ms)');
        suggestions.add('Profile the screen to identify slow frames');
      }
    }

    // Memory regression
    final memoryIncrease = current.medianMemoryMb - baseline.medianMemoryMb;
    if (memoryIncrease > memoryToleranceMb) {
      regressions.add('Memory increased ${memoryIncrease}MB '
          '(${baseline.medianMemoryMb}MB → ${current.medianMemoryMb}MB)');
      suggestions.add('Check for memory leaks — objects may not be disposed');
    }

    if (regressions.isEmpty) return null;

    return RegressionReport(
      screenName: current.screenName,
      severity: regressions.length >= 2 ? Severity.critical : Severity.warning,
      title: 'Performance Regression on ${current.screenName}',
      description: regressions.join('. '),
      suggestions: suggestions,
      baseline: baseline,
      current: current,
    );
  }
}
