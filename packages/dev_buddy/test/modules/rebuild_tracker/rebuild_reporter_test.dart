// packages/dev_buddy/test/modules/rebuild_tracker/rebuild_reporter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/modules/rebuild_tracker/rebuild_reporter.dart';
import 'package:dev_buddy/src/modules/rebuild_tracker/rebuild_counter.dart';
import 'package:dev_buddy/src/core/severity.dart';

void main() {
  group('RebuildReporter', () {
    late RebuildReporter reporter;

    setUp(() {
      reporter = const RebuildReporter(warningThreshold: 30);
    });

    test('returns null when below threshold', () {
      final counter = RebuildCounter();
      for (var i = 0; i < 10; i++) {
        counter.recordRebuild(String); // using Dart types as stand-ins
      }
      final result = reporter.evaluate(counter);
      expect(result, isNull);
    });

    test('returns warning when threshold exceeded', () {
      final counter = RebuildCounter();
      for (var i = 0; i < 35; i++) {
        counter.recordRebuild(String);
      }
      final result = reporter.evaluate(counter);
      expect(result, isNotNull);
      expect(result!.severity, equals(Severity.warning));
    });

    test('returns critical for extreme rebuilds', () {
      final counter = RebuildCounter();
      for (var i = 0; i < 100; i++) {
        counter.recordRebuild(String);
      }
      final result = reporter.evaluate(counter);
      expect(result, isNotNull);
      expect(result!.severity, equals(Severity.critical));
    });

    test('suggestions mention const constructors and widget extraction', () {
      final counter = RebuildCounter();
      for (var i = 0; i < 35; i++) {
        counter.recordRebuild(String);
      }
      final result = reporter.evaluate(counter);
      expect(result, isNotNull);
      expect(result!.suggestions.any((s) => s.contains('const')), isTrue);
    });
  });
}
