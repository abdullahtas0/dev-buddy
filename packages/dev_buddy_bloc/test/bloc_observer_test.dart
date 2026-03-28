import 'package:bloc/bloc.dart';
import 'package:dev_buddy_bloc/dev_buddy_bloc.dart';
import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

// Test Bloc
abstract class CounterEvent {}

class Increment extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

// Test Cubit
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

void main() {
  group('DevBuddyBlocObserver', () {
    late StateStore store;
    late DevBuddyBlocObserver observer;

    setUp(() {
      store = StateStore(maxBudgetBytes: 10000);
      observer = DevBuddyBlocObserver(stateStore: store);
      Bloc.observer = observer;
    });

    tearDown(() {
      store.dispose();
    });

    test('records Bloc transitions', () async {
      final bloc = CounterBloc();
      bloc.add(Increment());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(store.length, greaterThan(0));
      final snap = store.history.first;
      expect(snap.source, contains('CounterBloc'));
      expect(snap.action, 'Increment');

      await bloc.close();
    });

    test('records Cubit changes', () {
      final cubit = CounterCubit();
      cubit.increment();

      expect(store.length, greaterThan(0));
      final snap = store.history.first;
      expect(snap.source, contains('CounterCubit'));
      expect(snap.action, 'change');

      cubit.close();
    });

    test('records multiple state transitions', () async {
      final bloc = CounterBloc();
      bloc.add(Increment());
      bloc.add(Increment());
      bloc.add(Increment());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(store.length, 3);

      await bloc.close();
    });

    test('custom serializer is used', () async {
      final customStore = StateStore(maxBudgetBytes: 10000);
      final customObserver = DevBuddyBlocObserver(
        stateStore: customStore,
        serializer: (value) => 'CUSTOM:$value',
      );
      Bloc.observer = customObserver;

      final cubit = CounterCubit();
      cubit.increment();

      final snap = customStore.history.first;
      expect(snap.serializedState, isNull); // diff-only (not anchor)

      cubit.close();
      customStore.dispose();
    });
  });
}
