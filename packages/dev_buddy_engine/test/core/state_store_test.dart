import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

void main() {
  group('StateStore', () {
    late StateStore store;

    setUp(() {
      store = StateStore(
        maxBudgetBytes: 10000, // 10KB for testing
        anchorInterval: 3,
      );
    });

    tearDown(() => store.dispose());

    test('records a snapshot and increments version', () {
      final recorded = store.record(
        source: 'riverpod:counter',
        stateHashCode: 42,
        serializedState: '{"count": 0}',
        action: 'init',
      );

      expect(recorded, isTrue);
      expect(store.length, 1);
      expect(store.history.first.version, 1);
      expect(store.history.first.source, 'riverpod:counter');
      expect(store.history.first.action, 'init');
    });

    test('hashCode pre-filter skips unchanged state', () {
      store.record(
        source: 'riverpod:counter',
        stateHashCode: 42,
        serializedState: '{"count": 0}',
      );

      // Same hashCode — should skip
      final recorded = store.record(
        source: 'riverpod:counter',
        stateHashCode: 42,
        serializedState: '{"count": 0}',
      );

      expect(recorded, isFalse);
      expect(store.length, 1); // No new snapshot
    });

    test('hashCode pre-filter allows different hashCodes', () {
      store.record(source: 'counter', stateHashCode: 1, serializedState: '1');
      store.record(source: 'counter', stateHashCode: 2, serializedState: '2');
      store.record(source: 'counter', stateHashCode: 3, serializedState: '3');

      expect(store.length, 3);
    });

    test('different sources tracked independently', () {
      store.record(source: 'a', stateHashCode: 42, serializedState: '1');
      store.record(source: 'b', stateHashCode: 42, serializedState: '2');

      expect(store.length, 2); // Different sources, same hash is OK
    });

    test('anchor snapshots created at interval', () {
      // anchorInterval = 3, so every 3rd snapshot is an anchor
      for (var i = 0; i < 6; i++) {
        store.record(
          source: 'counter',
          stateHashCode: i,
          serializedState: '{"count": $i}',
          serializedDiff: '{"count": [$i]}',
        );
      }

      final anchors = store.history.where((s) => s.isAnchor).toList();
      expect(anchors, hasLength(2)); // snapshots 3 and 6
    });

    test('anchor snapshots store full state, diffs store diff', () {
      store.record(
        source: 'c',
        stateHashCode: 1,
        serializedState: '{"full": true}',
        serializedDiff: '{"diff": true}',
      );

      final snap = store.history.first;
      // First snapshot, snapshotsSinceAnchor=1, not anchor yet (interval=3)
      expect(snap.isAnchor, isFalse);
      expect(snap.serializedDiff, '{"diff": true}');
      expect(snap.serializedState, isNull);
    });

    test('RAM budget enforcement evicts oldest entries', () {
      // Each snapshot ~100 bytes. Budget 10000 bytes = ~100 snapshots.
      // But let's fill with larger data to trigger eviction sooner.
      final largeData = 'x' * 2000; // ~2KB per snapshot

      for (var i = 0; i < 10; i++) {
        store.record(
          source: 'big',
          stateHashCode: i,
          serializedState: largeData,
        );
      }

      // With 2KB per snapshot and 10KB budget, max ~5 snapshots
      expect(store.length, lessThanOrEqualTo(5));
      expect(store.usedBytes, lessThanOrEqualTo(10000));
    });

    test('budgetUsagePercent tracks usage', () {
      expect(store.budgetUsagePercent, 0.0);

      store.record(
        source: 'test',
        stateHashCode: 1,
        serializedState: 'x' * 5000, // ~5KB = 50% of 10KB budget
      );

      expect(store.budgetUsagePercent, greaterThan(0.4));
    });

    test('at() retrieves snapshot by version', () {
      store.record(source: 'a', stateHashCode: 1, serializedState: '1');
      store.record(source: 'a', stateHashCode: 2, serializedState: '2');
      store.record(source: 'a', stateHashCode: 3, serializedState: '3');

      expect(store.at(2)?.source, 'a');
      expect(store.at(999), isNull);
    });

    test('forSource() filters by source', () {
      store.record(
        source: 'riverpod:counter',
        stateHashCode: 1,
        serializedState: '1',
      );
      store.record(source: 'bloc:auth', stateHashCode: 2, serializedState: '2');
      store.record(
        source: 'riverpod:counter',
        stateHashCode: 3,
        serializedState: '3',
      );

      final riverpodSnaps = store.forSource('riverpod:counter');
      expect(riverpodSnaps, hasLength(2));
    });

    test('recent() returns N most recent, newest first', () {
      for (var i = 0; i < 5; i++) {
        store.record(source: 'c', stateHashCode: i, serializedState: '$i');
      }

      final recent = store.recent(3);
      expect(recent, hasLength(3));
      expect(recent.first.version, 5); // newest
      expect(recent.last.version, 3);
    });

    test('stream emits new snapshots', () async {
      final snapshots = <StateSnapshot>[];
      store.stream.listen(snapshots.add);

      store.record(source: 'a', stateHashCode: 1, serializedState: '1');
      await Future<void>.delayed(Duration.zero);

      expect(snapshots, hasLength(1));
    });

    test('clear resets all state', () {
      store.record(source: 'a', stateHashCode: 1, serializedState: '1');
      expect(store.length, 1);

      store.clear();
      expect(store.length, 0);
      expect(store.usedBytes, 0);
    });

    test('history returns immutable list', () {
      store.record(source: 'a', stateHashCode: 1, serializedState: '1');
      expect(
        () => store.history.add(
          StateSnapshot(version: 99, timestamp: DateTime.now(), source: 'hack'),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
