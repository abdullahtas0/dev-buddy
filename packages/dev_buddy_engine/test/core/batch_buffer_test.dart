import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

DevBuddyEvent _event({
  String module = 'test',
  Severity severity = Severity.info,
}) => DevBuddyEvent(
  module: module,
  severity: severity,
  title: 'Test',
  description: 'desc',
  suggestions: ['fix'],
);

void main() {
  group('BatchBuffer', () {
    late List<List<DevBuddyEvent>> flushedBatches;
    late BatchBuffer buffer;

    setUp(() {
      flushedBatches = [];
      buffer = BatchBuffer(onFlush: flushedBatches.add);
    });

    tearDown(() => buffer.dispose());

    test('immediate priority flushes instantly', () {
      buffer.add(
        _event(severity: Severity.critical),
        priority: EventPriority.immediate,
      );

      expect(flushedBatches, hasLength(1));
      expect(flushedBatches.first, hasLength(1));
    });

    test('immediate flush includes previously buffered lazy events', () {
      buffer.add(_event(module: 'perf'), priority: EventPriority.lazy);
      buffer.add(_event(module: 'perf'), priority: EventPriority.lazy);
      // Immediate event triggers flush of ALL buffered events
      buffer.add(
        _event(severity: Severity.critical),
        priority: EventPriority.immediate,
      );

      expect(flushedBatches, hasLength(1));
      expect(flushedBatches.first, hasLength(3));
    });

    test('lazy events are not flushed synchronously', () {
      buffer.add(_event(), priority: EventPriority.lazy);
      expect(flushedBatches, isEmpty);
    });

    test('flush() forces immediate flush', () {
      buffer.add(_event(), priority: EventPriority.lazy);
      buffer.add(_event(), priority: EventPriority.lazy);
      buffer.flush();

      expect(flushedBatches, hasLength(1));
      expect(flushedBatches.first, hasLength(2));
    });

    test('priorityFor returns immediate for critical events', () {
      final event = _event(severity: Severity.critical);
      expect(BatchBuffer.priorityFor(event), EventPriority.immediate);
    });

    test('priorityFor returns immediate for error translator events', () {
      final event = _event(module: 'error_translator');
      expect(BatchBuffer.priorityFor(event), EventPriority.immediate);
    });

    test('priorityFor returns fast for network events', () {
      final event = _event(module: 'network');
      expect(BatchBuffer.priorityFor(event), EventPriority.fast);
    });

    test('priorityFor returns lazy for performance events', () {
      final event = _event(module: 'performance');
      expect(BatchBuffer.priorityFor(event), EventPriority.lazy);
    });

    test('dispose flushes remaining events', () {
      buffer.add(_event(), priority: EventPriority.lazy);
      buffer.add(_event(), priority: EventPriority.lazy);
      buffer.dispose();

      expect(flushedBatches, hasLength(1));
      expect(flushedBatches.first, hasLength(2));
    });

    test('add after dispose is ignored', () {
      buffer.add(_event(), priority: EventPriority.lazy); // Add before dispose
      buffer.dispose(); // This flushes the 1 event

      flushedBatches.clear(); // Reset
      buffer.add(_event(), priority: EventPriority.immediate);

      // After dispose, no new flushes should occur
      expect(flushedBatches, isEmpty);
    });
  });
}
