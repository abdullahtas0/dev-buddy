import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:flutter_test/flutter_test.dart';

// We can't test dart:developer registerExtension directly in unit tests
// (it requires a running VM Service), but we can test the engine integration
// that the service extensions depend on.

class _FakeModule extends DiagnosticModule {
  @override
  String get id => 'test_module';
  @override
  String get displayName => 'Test Module';
  @override
  Map<String, dynamic> get currentState => {'status': 'active'};

  late void Function(DevBuddyEvent) _onEvent;

  @override
  void initialize({required DevBuddyConfig config, required void Function(DevBuddyEvent) onEvent}) {
    _onEvent = onEvent;
  }

  @override
  void dispose() {}

  void emit(String title, {Severity severity = Severity.warning}) {
    _onEvent(DevBuddyEvent(
      module: id,
      severity: severity,
      title: title,
      description: 'Test event',
      suggestions: ['Fix it'],
    ));
  }
}

void main() {
  group('Service Extensions Data Layer', () {
    late DevBuddyEngine engine;
    late _FakeModule module;

    setUp(() {
      module = _FakeModule();
      engine = DevBuddyEngine(
        modules: [module],
        config: const DevBuddyConfig(maxEvents: 50),
      );
      engine.initialize();
    });

    tearDown(() => engine.dispose());

    test('engine.snapshot() returns complete state for ext.dev_buddy.snapshot', () {
      module.emit('Test Warning');
      engine.flushForTesting();

      final snap = engine.snapshot();
      expect(snap['overall_severity'], isA<String>());
      expect(snap['event_count'], 1);
      expect(snap['modules'], containsPair('test_module', {'status': 'active'}));
      expect(snap['recent_events'], hasLength(1));
      expect(snap['state_store'], isA<Map>());
    });

    test('eventBus.history provides data for ext.dev_buddy.events', () {
      module.emit('Event 1');
      module.emit('Event 2');
      module.emit('Event 3');
      engine.flushForTesting();

      final events = engine.eventBus.history;
      expect(events, hasLength(3));

      // Simulate limit parameter
      final limited = events.take(2).toList();
      expect(limited, hasLength(2));

      // Simulate module filter
      final filtered = events.where((e) => e.module == 'test_module').toList();
      expect(filtered, hasLength(3));
    });

    test('stateStore provides data for ext.dev_buddy.state', () {
      engine.stateStore.record(
        source: 'riverpod:counter',
        stateHashCode: 42,
        serializedState: '{"count": 1}',
        action: 'increment',
      );

      final history = engine.stateStore.history;
      expect(history, hasLength(1));
      expect(history.first.source, 'riverpod:counter');

      // Simulate source filter
      final filtered = history.where((s) => s.source.contains('counter')).toList();
      expect(filtered, hasLength(1));
    });

    test('clearEvents + stateStore.clear provides ext.dev_buddy.clear', () {
      module.emit('Will be cleared');
      engine.flushForTesting();
      engine.stateStore.record(
        source: 'test',
        stateHashCode: 1,
        serializedState: 'data',
      );

      expect(engine.eventBus.length, 1);
      expect(engine.stateStore.length, 1);

      engine.clearEvents();
      engine.stateStore.clear();

      expect(engine.eventBus.length, 0);
      expect(engine.stateStore.length, 0);
    });

    test('snapshot JSON is serializable (no circular refs)', () {
      module.emit('Event');
      engine.flushForTesting();

      final snap = engine.snapshot();
      // Should not throw
      expect(() => snap.toString(), returnsNormally);
      expect(snap['recent_events'], isA<List>());
      for (final event in snap['recent_events'] as List) {
        expect(event, isA<Map>());
        expect((event as Map)['module'], 'test_module');
      }
    });
  });
}
