import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

class FakeModule extends DiagnosticModule {
  @override
  String get id => 'fake';
  @override
  String get displayName => 'Fake Module';
  @override
  Map<String, dynamic> get currentState => {'active': true};

  late void Function(DevBuddyEvent) _onEvent;
  bool initialized = false;
  bool disposed = false;

  @override
  void initialize({
    required DevBuddyConfig config,
    required void Function(DevBuddyEvent) onEvent,
  }) {
    _onEvent = onEvent;
    initialized = true;
  }

  @override
  void dispose() => disposed = true;

  void emitEvent({
    Severity severity = Severity.info,
    String title = 'Fake Event',
  }) {
    _onEvent(
      DevBuddyEvent(
        module: id,
        severity: severity,
        title: title,
        description: 'Fake description',
        suggestions: ['Fix it'],
      ),
    );
  }
}

void main() {
  group('DevBuddyEngine', () {
    late FakeModule fakeModule;
    late DevBuddyEngine engine;

    setUp(() {
      fakeModule = FakeModule();
      engine = DevBuddyEngine(
        modules: [fakeModule],
        config: const DevBuddyConfig(maxEvents: 5),
      );
      engine.initialize();
    });

    tearDown(() => engine.dispose());

    test('initializes all modules', () {
      expect(fakeModule.initialized, isTrue);
    });

    test('disposes all modules', () {
      engine.dispose();
      expect(fakeModule.disposed, isTrue);
    });

    test('double dispose does not throw', () {
      engine.dispose();
      expect(() => engine.dispose(), returnsNormally);
    });

    test('events flow from module through batch buffer to event bus', () {
      fakeModule.emitEvent();
      engine.flushForTesting();

      expect(engine.eventBus.length, equals(1));
      expect(engine.eventBus.history.first.title, 'Fake Event');
    });

    test('filters events below minSeverity', () {
      final strictEngine = DevBuddyEngine(
        modules: [fakeModule],
        config: const DevBuddyConfig(minSeverity: Severity.warning),
      );
      strictEngine.initialize();

      fakeModule.emitEvent(severity: Severity.info);
      strictEngine.flushForTesting();

      expect(strictEngine.eventBus.length, equals(0));
      strictEngine.dispose();
    });

    test('updates overall severity after flush', () {
      expect(engine.overallSeverity, Severity.info);

      fakeModule.emitEvent(severity: Severity.critical);
      engine.flushForTesting();

      expect(engine.overallSeverity, Severity.critical);
    });

    test('clearEvents resets history and severity', () {
      fakeModule.emitEvent(severity: Severity.warning);
      engine.flushForTesting();
      expect(engine.eventBus.length, greaterThan(0));

      engine.clearEvents();
      expect(engine.eventBus.length, equals(0));
      expect(engine.overallSeverity, Severity.info);
    });

    test('eventsForModule filters by module id', () {
      fakeModule.emitEvent(title: 'First');
      engine.flushForTesting();

      expect(engine.eventsForModule('fake'), hasLength(1));
      expect(engine.eventsForModule('nonexistent'), isEmpty);
    });

    test('snapshot returns serializable state', () {
      fakeModule.emitEvent();
      engine.flushForTesting();

      final snap = engine.snapshot();
      expect(snap['overall_severity'], 'info');
      expect(snap['event_count'], 1);
      expect(snap['modules'], containsPair('fake', {'active': true}));
      expect(snap['recent_events'], hasLength(1));
    });

    test('ignores events after dispose', () {
      engine.dispose();
      expect(() => fakeModule.emitEvent(), returnsNormally);
    });

    test('onStateChanged callback fires after flush', () {
      var callCount = 0;
      engine.onStateChanged = (events, severity) => callCount++;

      fakeModule.emitEvent();
      engine.flushForTesting();

      expect(callCount, equals(1));
    });

    test('modules list is unmodifiable', () {
      expect(engine.modules, hasLength(1));
      expect(
        () => (engine.modules as List).add(FakeModule()),
        throwsUnsupportedError,
      );
    });
  });
}
