import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

DevBuddyEvent _event({
  String module = 'test',
  Severity severity = Severity.info,
  String title = 'Test Event',
}) =>
    DevBuddyEvent(
      module: module,
      severity: severity,
      title: title,
      description: 'desc',
      suggestions: ['fix it'],
    );

void main() {
  group('EventBus', () {
    late EventBus bus;

    setUp(() => bus = EventBus(maxHistory: 5));
    tearDown(() => bus.dispose());

    test('emits events to stream listeners', () async {
      final events = <DevBuddyEvent>[];
      bus.stream.listen(events.add);

      bus.emit(_event());
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.title, 'Test Event');
    });

    test('stores events in history, newest first', () {
      bus.emit(_event(title: 'First'));
      bus.emit(_event(title: 'Second'));

      expect(bus.history, hasLength(2));
      expect(bus.history.first.title, 'Second');
      expect(bus.history.last.title, 'First');
    });

    test('enforces maxHistory limit', () {
      for (var i = 0; i < 8; i++) {
        bus.emit(_event(title: 'Event $i'));
      }

      expect(bus.length, equals(5));
      expect(bus.droppedCount, equals(3));
    });

    test('filters by module', () async {
      final networkEvents = <DevBuddyEvent>[];
      bus.forModule('network').listen(networkEvents.add);

      bus.emit(_event(module: 'network'));
      bus.emit(_event(module: 'performance'));
      bus.emit(_event(module: 'network'));
      await Future<void>.delayed(Duration.zero);

      expect(networkEvents, hasLength(2));
    });

    test('filters by severity', () async {
      final warnings = <DevBuddyEvent>[];
      bus.ofSeverity(Severity.warning).listen(warnings.add);

      bus.emit(_event(severity: Severity.info));
      bus.emit(_event(severity: Severity.warning));
      bus.emit(_event(severity: Severity.critical));
      await Future<void>.delayed(Duration.zero);

      expect(warnings, hasLength(2));
    });

    test('emitBatch processes multiple events efficiently', () {
      final batch = List.generate(3, (i) => _event(title: 'Batch $i'));
      bus.emitBatch(batch);

      expect(bus.length, equals(3));
      expect(bus.history.first.title, 'Batch 2');
    });

    test('emitBatch enforces maxHistory after batch', () {
      final batch = List.generate(8, (i) => _event(title: 'Batch $i'));
      bus.emitBatch(batch);

      expect(bus.length, equals(5));
      expect(bus.droppedCount, equals(3));
    });

    test('historyFor returns events for specific module', () {
      bus.emit(_event(module: 'network'));
      bus.emit(_event(module: 'performance'));
      bus.emit(_event(module: 'network'));

      final networkHistory = bus.historyFor('network');
      expect(networkHistory, hasLength(2));
    });

    test('clear resets history and dropped count', () {
      for (var i = 0; i < 8; i++) {
        bus.emit(_event());
      }
      expect(bus.droppedCount, greaterThan(0));

      bus.clear();
      expect(bus.length, equals(0));
      expect(bus.droppedCount, equals(0));
    });

    test('emit after dispose is silently ignored', () {
      bus.dispose();
      expect(() => bus.emit(_event()), returnsNormally);
    });

    test('history returns immutable list', () {
      bus.emit(_event());
      expect(() => bus.history.add(_event()), throwsUnsupportedError);
    });
  });
}
