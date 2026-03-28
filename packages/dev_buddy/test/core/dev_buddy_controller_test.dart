// packages/dev_buddy/test/core/dev_buddy_controller_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/core/dev_buddy_controller.dart';
import 'package:dev_buddy/src/core/dev_buddy_config.dart';
import 'package:dev_buddy/src/core/dev_buddy_event.dart';
import 'package:dev_buddy/src/core/dev_buddy_module.dart';
import 'package:dev_buddy/src/core/severity.dart';

class _FakeModule extends DevBuddyModule {
  @override
  String get id => 'fake';
  @override
  String get name => 'Fake';
  @override
  IconData get icon => Icons.bug_report;

  late void Function(DevBuddyEvent) _onEvent;

  @override
  void initialize({
    required DevBuddyConfig config,
    required void Function(DevBuddyEvent) onEvent,
  }) {
    _onEvent = onEvent;
  }

  @override
  void dispose() {}

  @override
  Widget buildTab(BuildContext context, List<DevBuddyEvent> events) {
    return const SizedBox.shrink();
  }

  void emitFakeEvent(Severity severity) {
    _onEvent(DevBuddyEvent(
      module: id,
      severity: severity,
      title: 'Fake event',
      description: 'Test',
      suggestions: [],
    ));
  }
}

void main() {
  group('DevBuddyController', () {
    late DevBuddyController controller;
    late _FakeModule fakeModule;

    setUp(() {
      fakeModule = _FakeModule();
      controller = DevBuddyController(
        modules: [fakeModule],
        config: const DevBuddyConfig(maxEvents: 5),
      );
      controller.initialize();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initializes with empty events', () {
      expect(controller.events.value, isEmpty);
    });

    // NOTE: Events are batched with a 500ms flush timer.
    // Tests must use fake async or wait for flush to verify state.

    test('receives events from modules after flush', () {
      fakeModule.emitFakeEvent(Severity.warning);
      // Manually flush pending events (in real code, timer triggers this)
      controller.flushForTesting();
      expect(controller.events.value, hasLength(1));
      expect(controller.events.value.first.module, equals('fake'));
    });

    test('evicts oldest events when maxEvents exceeded', () {
      for (var i = 0; i < 7; i++) {
        fakeModule.emitFakeEvent(Severity.info);
      }
      controller.flushForTesting();
      expect(controller.events.value, hasLength(5)); // maxEvents = 5
    });

    test('overallSeverity reflects highest active severity', () {
      expect(controller.overallSeverity.value, equals(Severity.info));
      fakeModule.emitFakeEvent(Severity.warning);
      controller.flushForTesting();
      expect(controller.overallSeverity.value, equals(Severity.warning));
      fakeModule.emitFakeEvent(Severity.critical);
      controller.flushForTesting();
      expect(controller.overallSeverity.value, equals(Severity.critical));
    });

    test('eventsForModule filters by module id', () {
      fakeModule.emitFakeEvent(Severity.info);
      controller.flushForTesting();
      expect(controller.eventsForModule('fake'), hasLength(1));
      expect(controller.eventsForModule('other'), isEmpty);
    });

    test('clearEvents resets state including pending buffer', () {
      fakeModule.emitFakeEvent(Severity.critical);
      controller.clearEvents();
      controller.flushForTesting(); // should be nothing to flush
      expect(controller.events.value, isEmpty);
      expect(controller.overallSeverity.value, equals(Severity.info));
    });

    test('batches rapid events into single UI update', () {
      var notifyCount = 0;
      controller.events.addListener(() => notifyCount++);
      for (var i = 0; i < 10; i++) {
        fakeModule.emitFakeEvent(Severity.info);
      }
      controller.flushForTesting();
      // All 10 events should arrive in a single notification
      expect(notifyCount, equals(1));
      expect(controller.events.value, hasLength(5)); // capped at maxEvents
    });

    test('double dispose does not throw', () {
      // First dispose is in tearDown, manually call it before
      controller.dispose();
      // tearDown will call dispose() again - should not throw
      expect(() => controller.dispose(), returnsNormally);
    });

    test('tracks dropped event count when maxEvents exceeded', () {
      expect(controller.droppedEventCount.value, equals(0));
      for (var i = 0; i < 8; i++) {
        fakeModule.emitFakeEvent(Severity.info);
      }
      controller.flushForTesting();
      // maxEvents is 5, so 3 should be dropped
      expect(controller.droppedEventCount.value, equals(3));
    });

    test('clearEvents resets dropped event count', () {
      for (var i = 0; i < 8; i++) {
        fakeModule.emitFakeEvent(Severity.info);
      }
      controller.flushForTesting();
      expect(controller.droppedEventCount.value, greaterThan(0));
      controller.clearEvents();
      expect(controller.droppedEventCount.value, equals(0));
    });

    test('ignores events after dispose', () {
      controller.dispose();
      // Should not throw when module emits after dispose
      expect(() => fakeModule.emitFakeEvent(Severity.info), returnsNormally);
    });

    test('filters events below minSeverity', () {
      final strictController = DevBuddyController(
        modules: [fakeModule],
        config: const DevBuddyConfig(minSeverity: Severity.warning),
      );
      strictController.initialize();
      fakeModule.emitFakeEvent(Severity.info); // should be dropped
      strictController.flushForTesting();
      expect(strictController.events.value, isEmpty);
      fakeModule.emitFakeEvent(Severity.warning); // should be kept
      strictController.flushForTesting();
      expect(strictController.events.value, hasLength(1));
      strictController.dispose();
    });
  });
}
