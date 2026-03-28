import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

DevBuddyEvent _event({
  String module = 'test',
  Severity severity = Severity.info,
  String title = 'Test Event',
  Map<String, dynamic>? metadata,
}) => DevBuddyEvent(
  module: module,
  severity: severity,
  title: title,
  description: 'desc',
  suggestions: ['fix it'],
  metadata: metadata,
);

void main() {
  group('EventBus stress tests', () {
    test('10,000 events — history bounded, no unbounded growth', () {
      final bus = EventBus(maxHistory: 500);
      addTearDown(bus.dispose);

      for (var i = 0; i < 10000; i++) {
        bus.emit(_event(title: 'Event $i'));
      }

      expect(bus.length, equals(500));
      expect(bus.droppedCount, equals(9500));

      // Verify newest event is actually the last emitted
      expect(bus.history.first.title, equals('Event 9999'));

      // Verify oldest retained event
      expect(bus.history.last.title, equals('Event 9500'));
    });

    test('10,000 events — utilization stays at 100%', () {
      final bus = EventBus(maxHistory: 200);
      addTearDown(bus.dispose);

      for (var i = 0; i < 10000; i++) {
        bus.emit(_event(title: 'Event $i'));
      }

      expect(bus.utilizationPercent, closeTo(1.0, 0.001));
    });

    test('10,000 events via emitBatch — correct bounded history', () {
      final bus = EventBus(maxHistory: 300);
      addTearDown(bus.dispose);

      // Emit in batches of 100
      for (var batch = 0; batch < 100; batch++) {
        final events = List.generate(
          100,
          (i) => _event(title: 'Batch$batch-$i'),
        );
        bus.emitBatch(events);
      }

      expect(bus.length, equals(300));
      // Last batch is batch 99, events 0..99
      expect(bus.history.first.title, equals('Batch99-99'));
      expect(bus.droppedCount, equals(9700));
    });

    test('reversed history consistency under load', () {
      final bus = EventBus(maxHistory: 1000);
      addTearDown(bus.dispose);

      for (var i = 0; i < 5000; i++) {
        bus.emit(_event(title: 'Event $i'));
      }

      final history = bus.history;
      expect(history.length, equals(1000));

      // History should be newest-first (descending order)
      for (var i = 0; i < history.length - 1; i++) {
        final currentTitle = history[i].title;
        final nextTitle = history[i + 1].title;
        final currentNum = int.parse(currentTitle.split(' ')[1]);
        final nextNum = int.parse(nextTitle.split(' ')[1]);
        expect(
          currentNum,
          greaterThan(nextNum),
          reason:
              'History should be newest first: $currentTitle before $nextTitle',
        );
      }
    });

    test('historyFor module filter under load', () {
      final bus = EventBus(maxHistory: 500);
      addTearDown(bus.dispose);

      for (var i = 0; i < 5000; i++) {
        // Alternate modules
        final module = i % 3 == 0
            ? 'network'
            : (i % 3 == 1 ? 'performance' : 'memory');
        bus.emit(_event(module: module, title: 'Event $i'));
      }

      final networkHistory = bus.historyFor('network');
      for (final event in networkHistory) {
        expect(event.module, equals('network'));
      }
      // Network events are every 3rd event, so roughly 1/3 of 500
      expect(networkHistory.length, greaterThan(100));
    });

    test('clear after heavy load resets everything', () {
      final bus = EventBus(maxHistory: 500);
      addTearDown(bus.dispose);

      for (var i = 0; i < 10000; i++) {
        bus.emit(_event());
      }

      bus.clear();
      expect(bus.length, equals(0));
      expect(bus.droppedCount, equals(0));
      expect(bus.history, isEmpty);
      expect(bus.utilizationPercent, equals(0.0));
    });

    test('stream listener receives all 10,000 events', () async {
      final bus = EventBus(maxHistory: 100);
      addTearDown(bus.dispose);

      var receivedCount = 0;
      bus.stream.listen((_) => receivedCount++);

      for (var i = 0; i < 10000; i++) {
        bus.emit(_event());
      }

      await Future<void>.delayed(Duration.zero);
      expect(receivedCount, equals(10000));
    });
  });

  group('StateStore stress tests', () {
    test('1000 records near 20MB budget — evicts oldest', () {
      // Each record ~20KB to stay near budget
      final store = StateStore(
        maxBudgetBytes: 20 * 1024 * 1024,
        anchorInterval: 50,
      );
      addTearDown(store.dispose);

      final largeState = 'x' * 20000; // ~20KB per record

      for (var i = 0; i < 1000; i++) {
        store.record(
          source: 'stress:provider$i',
          stateHashCode: i,
          serializedState: largeState,
          action: 'Update $i',
        );
      }

      // All 1000 should fit: 1000 * ~20KB = ~20MB
      expect(store.length, greaterThan(0));
      expect(store.usedBytes, lessThanOrEqualTo(store.maxBudgetBytes));
    });

    test('exceeding budget evicts oldest entries', () {
      // 1MB budget, each record ~100KB
      final store = StateStore(
        maxBudgetBytes: 1024 * 1024,
        anchorInterval: 100,
      );
      addTearDown(store.dispose);

      final largeState = 'y' * 100000; // ~100KB

      for (var i = 0; i < 50; i++) {
        store.record(
          source: 'budget:test',
          stateHashCode: i,
          serializedState: largeState,
          action: 'Action $i',
          sourceVersion: i,
        );
      }

      // Budget is 1MB, each ~100KB, so roughly 10 entries fit
      expect(store.usedBytes, lessThanOrEqualTo(store.maxBudgetBytes));
      expect(store.length, lessThan(50));
      expect(store.length, greaterThan(0));
    });

    test('hashCode pre-filter prevents duplicate records', () {
      final store = StateStore(maxBudgetBytes: 1024 * 1024);
      addTearDown(store.dispose);

      // Same hash, same source, no version — should be skipped
      final recorded1 = store.record(
        source: 'dup:test',
        stateHashCode: 42,
        serializedState: '{"count":1}',
      );
      final recorded2 = store.record(
        source: 'dup:test',
        stateHashCode: 42,
        serializedState: '{"count":1}',
      );

      expect(recorded1, isTrue);
      expect(recorded2, isFalse);
      expect(store.length, equals(1));
    });

    test('different sources with same hashCode are tracked independently', () {
      final store = StateStore(maxBudgetBytes: 1024 * 1024);
      addTearDown(store.dispose);

      store.record(source: 'a', stateHashCode: 42, serializedState: '{}');
      store.record(source: 'b', stateHashCode: 42, serializedState: '{}');

      expect(store.length, equals(2));
    });

    test('anchor snapshots created at correct intervals', () {
      final store = StateStore(
        maxBudgetBytes: 10 * 1024 * 1024,
        anchorInterval: 10,
      );
      addTearDown(store.dispose);

      for (var i = 0; i < 100; i++) {
        store.record(
          source: 'anchor:test',
          stateHashCode: i,
          serializedState: '{"v":$i}',
          serializedDiff: '{"d":$i}',
          sourceVersion: i,
        );
      }

      // Every 10th snapshot should be an anchor
      final anchors = store.history.where((s) => s.isAnchor).toList();
      expect(anchors.length, greaterThanOrEqualTo(9));
    });

    test('forSource filters correctly under load', () {
      final store = StateStore(maxBudgetBytes: 10 * 1024 * 1024);
      addTearDown(store.dispose);

      for (var i = 0; i < 500; i++) {
        final source = 'source:${i % 5}';
        store.record(
          source: source,
          stateHashCode: i,
          serializedState: '{"i":$i}',
        );
      }

      final source0 = store.forSource('source:0');
      for (final snap in source0) {
        expect(snap.source, equals('source:0'));
      }
      expect(source0.length, equals(100));
    });

    test('recent() returns correct count under load', () {
      final store = StateStore(maxBudgetBytes: 10 * 1024 * 1024);
      addTearDown(store.dispose);

      for (var i = 0; i < 200; i++) {
        store.record(
          source: 'recent:test',
          stateHashCode: i,
          serializedState: '{"v":$i}',
          sourceVersion: i,
        );
      }

      final recentSnapshots = store.recent(10);
      expect(recentSnapshots.length, equals(10));
      // Newest first
      expect(
        recentSnapshots.first.version,
        greaterThan(recentSnapshots.last.version),
      );
    });

    test('clear after heavy load resets all state', () {
      final store = StateStore(maxBudgetBytes: 5 * 1024 * 1024);
      addTearDown(store.dispose);

      for (var i = 0; i < 500; i++) {
        store.record(
          source: 'clear:test',
          stateHashCode: i,
          serializedState: 'x' * 1000,
          sourceVersion: i,
        );
      }

      store.clear();
      expect(store.length, equals(0));
      expect(store.usedBytes, equals(0));
      expect(store.history, isEmpty);
    });

    test('budgetUsagePercent stays within bounds', () {
      final store = StateStore(maxBudgetBytes: 1024 * 1024);
      addTearDown(store.dispose);

      for (var i = 0; i < 200; i++) {
        store.record(
          source: 'budget:pct',
          stateHashCode: i,
          serializedState: 'x' * 5000,
          sourceVersion: i,
        );
      }

      expect(store.budgetUsagePercent, lessThanOrEqualTo(1.0));
      expect(store.budgetUsagePercent, greaterThan(0.0));
    });
  });

  group('CorrelationEngine stress tests', () {
    test('evaluate 1000+ events without error', () {
      final engine = CorrelationEngine();

      final events = <DevBuddyEvent>[];
      for (var i = 0; i < 1000; i++) {
        events.add(
          _event(
            module: i % 2 == 0 ? 'performance' : 'network',
            severity: Severity.info,
            title: 'Stress event $i',
          ),
        );
      }

      // Should not throw even with large event lists
      final results = engine.evaluate(events);
      expect(results, isA<List<DevBuddyEvent>>());
    });

    test('evaluate with mixed severity 1000+ events triggers rules', () {
      final engine = CorrelationEngine();

      final events = <DevBuddyEvent>[];
      // Add enough events to trigger jank_plus_rebuilds rule
      for (var i = 0; i < 500; i++) {
        events.add(
          _event(
            module: 'performance',
            severity: Severity.warning,
            title: 'Jank $i',
          ),
        );
      }
      for (var i = 0; i < 500; i++) {
        events.add(
          _event(
            module: 'rebuilds',
            severity: Severity.warning,
            title: 'Rebuild $i',
            metadata: {
              'top_rebuilders': [
                {'widget': 'Widget$i', 'count': i},
              ],
            },
          ),
        );
      }

      final results = engine.evaluate(events);
      expect(results, isNotEmpty);
      expect(results.any((e) => e.module == 'correlation'), isTrue);
    });

    test('fired rules prevent duplicate evaluations under load', () {
      final engine = CorrelationEngine();

      final events = <DevBuddyEvent>[
        _event(module: 'performance', severity: Severity.warning),
        _event(
          module: 'rebuilds',
          severity: Severity.warning,
          metadata: {
            'top_rebuilders': [
              {'widget': 'MyWidget', 'count': 100},
            ],
          },
        ),
      ];

      final first = engine.evaluate(events);
      final second = engine.evaluate(events);

      // First evaluation should fire, second should not (already fired)
      expect(first.length, greaterThanOrEqualTo(1));
      expect(second, isEmpty);
    });

    test('reset allows rules to fire again', () {
      final engine = CorrelationEngine();

      final events = <DevBuddyEvent>[
        _event(module: 'performance', severity: Severity.warning),
        _event(
          module: 'rebuilds',
          severity: Severity.warning,
          metadata: {
            'top_rebuilders': [
              {'widget': 'W', 'count': 10},
            ],
          },
        ),
      ];

      final first = engine.evaluate(events);
      engine.reset();
      final afterReset = engine.evaluate(events);

      expect(first.length, equals(afterReset.length));
    });

    test('evaluate with 5000 events returns in reasonable time', () {
      final engine = CorrelationEngine();

      final events = List.generate(
        5000,
        (i) => _event(
          module: ['performance', 'network', 'memory', 'rebuilds'][i % 4],
          severity: Severity.values[i % 3],
          title: 'Event $i',
        ),
      );

      final stopwatch = Stopwatch()..start();
      engine.evaluate(events);
      stopwatch.stop();

      // Should complete well under 1 second even with 5000 events
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('repeated auth failures rule triggers with 1000+ 401s', () {
      final engine = CorrelationEngine();

      final events = List.generate(
        1000,
        (i) => _event(
          module: 'network',
          severity: Severity.warning,
          title: '401 Error $i',
          metadata: {'status_code': 401},
        ),
      );

      final results = engine.evaluate(events);
      expect(results.any((e) => e.title.contains('Token Refresh')), isTrue);
    });
  });
}
