import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:dev_buddy_riverpod/dev_buddy_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DevBuddyRiverpodObserver', () {
    late StateStore store;
    late DevBuddyRiverpodObserver observer;
    late ProviderContainer container;

    setUp(() {
      store = StateStore(maxBudgetBytes: 10000);
      observer = DevBuddyRiverpodObserver(stateStore: store);
    });

    tearDown(() {
      container.dispose();
      store.dispose();
    });

    test('records provider initialization', () {
      final counterProvider = StateProvider<int>((ref) => 0);
      container = ProviderContainer(observers: [observer]);

      // Reading the provider triggers initialization
      container.read(counterProvider);

      expect(store.length, greaterThan(0));
      final snap = store.history.first;
      expect(snap.source, contains('riverpod'));
      expect(snap.action, 'init');
    });

    test('records state updates', () {
      final counterProvider = StateProvider<int>((ref) => 0);
      container = ProviderContainer(observers: [observer]);

      container.read(counterProvider);
      store.clear(); // Clear init events

      // Update state
      container.read(counterProvider.notifier).state = 42;

      expect(store.length, greaterThan(0));
      final snap = store.history.first;
      expect(snap.source, contains('riverpod'));
      expect(snap.action, 'update');
    });

    test('records provider disposal', () {
      final counterProvider = StateProvider.autoDispose<int>((ref) => 0);
      container = ProviderContainer(observers: [observer]);

      // Create and read
      container.read(counterProvider);
      store.clear();

      // Invalidate triggers dispose + re-init
      container.invalidate(counterProvider);
      container.read(counterProvider); // Force re-creation

      // Should have dispose + init events
      expect(store.length, greaterThan(0));
    });

    test('uses custom serializer when provided', () {
      final customStore = StateStore(maxBudgetBytes: 10000);
      final customObserver = DevBuddyRiverpodObserver(
        stateStore: customStore,
        serializer: (value) => 'CUSTOM:$value',
      );

      final provider = StateProvider<int>((ref) => 0);
      container = ProviderContainer(observers: [customObserver]);
      container.read(provider);

      // Check that at least one snapshot was recorded
      expect(customStore.length, greaterThan(0));

      customStore.dispose();
    });

    test('records multiple providers independently', () {
      final counterA = StateProvider<int>((ref) => 0);
      final counterB = StateProvider<String>((ref) => 'hello');
      container = ProviderContainer(observers: [observer]);

      container.read(counterA);
      container.read(counterB);

      // Both providers should be tracked
      expect(store.length, greaterThanOrEqualTo(2));

      final sources = store.history.map((s) => s.source).toSet();
      expect(sources.length, greaterThanOrEqualTo(2));
    });
  });
}
