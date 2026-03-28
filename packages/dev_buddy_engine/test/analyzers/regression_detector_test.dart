import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

PerformanceBaseline _baseline({
  double fps = 60,
  double frameMs = 16,
  int rebuilds = 20,
  int memoryMb = 100,
}) => PerformanceBaseline(
  screenName: '/home',
  medianFps: fps,
  p95FrameDurationMs: frameMs,
  medianRebuildCount: rebuilds,
  medianMemoryMb: memoryMb,
  recordedAt: DateTime.now(),
);

void main() {
  group('RegressionDetector', () {
    const detector = RegressionDetector();

    test('returns null when within tolerance', () {
      final baseline = _baseline(fps: 60);
      final current = _baseline(fps: 58); // 3.3% drop, under 10%
      expect(detector.compare(baseline, current), isNull);
    });

    test('detects FPS regression', () {
      final baseline = _baseline(fps: 60);
      final current = _baseline(fps: 45); // 25% drop
      final report = detector.compare(baseline, current);

      expect(report, isNotNull);
      expect(report!.severity, Severity.warning);
      expect(report.description, contains('FPS dropped'));
    });

    test('detects frame duration regression', () {
      final baseline = _baseline(frameMs: 16);
      final current = _baseline(frameMs: 25); // 56% increase
      final report = detector.compare(baseline, current);

      expect(report, isNotNull);
      expect(report!.description, contains('P95 frame time'));
    });

    test('detects memory regression', () {
      final baseline = _baseline(memoryMb: 100);
      final current = _baseline(memoryMb: 180); // 80MB increase
      final report = detector.compare(baseline, current);

      expect(report, isNotNull);
      expect(report!.description, contains('Memory increased'));
    });

    test('multiple regressions produce critical severity', () {
      final baseline = _baseline(fps: 60, memoryMb: 100);
      final current = _baseline(fps: 30, memoryMb: 200);
      final report = detector.compare(baseline, current);

      expect(report!.severity, Severity.critical);
    });

    test('custom tolerance thresholds', () {
      const strict = RegressionDetector(fpsTolerancePercent: 5.0);
      final baseline = _baseline(fps: 60);
      final current = _baseline(fps: 55); // 8.3% drop

      // Default (10%) would pass, strict (5%) should fail
      expect(detector.compare(baseline, current), isNull);
      expect(strict.compare(baseline, current), isNotNull);
    });

    test('baseline serialization round-trip', () {
      final original = _baseline(
        fps: 59.5,
        frameMs: 17.2,
        rebuilds: 15,
        memoryMb: 120,
      );
      final json = original.toJson();
      final restored = PerformanceBaseline.fromJson(json);

      expect(restored.screenName, original.screenName);
      expect(restored.medianFps, original.medianFps);
      expect(restored.p95FrameDurationMs, original.p95FrameDurationMs);
      expect(restored.medianRebuildCount, original.medianRebuildCount);
      expect(restored.medianMemoryMb, original.medianMemoryMb);
    });
  });
}
