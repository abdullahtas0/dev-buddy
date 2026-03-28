// packages/dev_buddy/test/modules/rebuild_tracker/rebuild_counter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/modules/rebuild_tracker/rebuild_counter.dart';

void main() {
  group('RebuildCounter', () {
    late RebuildCounter counter;

    setUp(() {
      counter = RebuildCounter();
    });

    test('tracks rebuilds per widget Type', () {
      counter.recordRebuild(String); // using Dart types as test stand-ins
      counter.recordRebuild(String);
      counter.recordRebuild(int);
      expect(counter.countFor(String), equals(2));
      expect(counter.countFor(int), equals(1));
    });

    test('returns 0 for unknown widget type', () {
      expect(counter.countFor(double), equals(0));
    });

    test('topRebuilders returns sorted by count descending', () {
      counter.recordRebuild(String);
      counter.recordRebuild(int);
      counter.recordRebuild(int);
      counter.recordRebuild(double);
      counter.recordRebuild(double);
      counter.recordRebuild(double);

      final top = counter.topRebuilders(2);
      expect(top.first.key, equals(double));
      expect(top.first.value, equals(3));
      expect(top[1].key, equals(int));
    });

    test('topRebuildersAsString converts Type to String for UI', () {
      counter.recordRebuild(String);
      counter.recordRebuild(String);
      final top = counter.topRebuildersAsString(1);
      expect(top.first.key, equals('String'));
      expect(top.first.value, equals(2));
    });

    test('resetFrame clears per-frame counts', () {
      counter.recordRebuild(String);
      counter.resetFrame();
      expect(counter.frameRebuildCount, equals(0));
    });

    test('frameRebuildCount tracks current frame total', () {
      counter.recordRebuild(String);
      counter.recordRebuild(int);
      counter.recordRebuild(double);
      expect(counter.frameRebuildCount, equals(3));
    });
  });
}
