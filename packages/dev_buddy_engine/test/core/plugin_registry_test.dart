import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

class FakePlugin extends DevBuddyPlugin {
  @override
  final String id;
  @override
  String get displayName => 'Fake $id';
  @override
  String get version => '1.0.0';
  @override
  final List<String> dependencies;

  bool registered = false;
  bool disposed = false;

  FakePlugin(this.id, {this.dependencies = const []});

  @override
  void onRegister(DevBuddyEngine engine) => registered = true;
  @override
  void onDispose() => disposed = true;
  @override
  Map<String, dynamic> get currentState => {'id': id};
}

void main() {
  group('PluginRegistry', () {
    late PluginRegistry registry;

    setUp(() => registry = PluginRegistry());

    test('registers and retrieves plugins', () {
      final plugin = FakePlugin('test');
      registry.register(plugin);

      expect(registry.length, 1);
      expect(registry.has('test'), isTrue);
      expect(registry.getById('test'), same(plugin));
    });

    test('retrieves plugin by type', () {
      final plugin = FakePlugin('test');
      registry.register(plugin);

      expect(registry.get<FakePlugin>(), same(plugin));
    });

    test('returns null for unregistered plugin', () {
      expect(registry.getById('nonexistent'), isNull);
      expect(registry.get<FakePlugin>(), isNull);
    });

    test('throws on duplicate registration', () {
      registry.register(FakePlugin('test'));
      expect(
        () => registry.register(FakePlugin('test')),
        throwsA(isA<DuplicatePluginException>()),
      );
    });

    test('validates dependencies — all satisfied', () {
      registry.register(FakePlugin('base'));
      registry.register(FakePlugin('dependent', dependencies: ['base']));

      expect(() => registry.validateDependencies(), returnsNormally);
    });

    test('validates dependencies — missing dependency throws', () {
      registry.register(FakePlugin('dependent', dependencies: ['missing']));

      expect(
        () => registry.validateDependencies(),
        throwsA(isA<PluginDependencyException>()),
      );
    });

    test('disposeAll disposes in reverse order', () {
      final first = FakePlugin('first');
      final second = FakePlugin('second');
      registry.register(first);
      registry.register(second);

      registry.disposeAll();

      expect(first.disposed, isTrue);
      expect(second.disposed, isTrue);
      expect(registry.length, 0);
    });

    test('all returns immutable list', () {
      registry.register(FakePlugin('a'));
      registry.register(FakePlugin('b'));

      final all = registry.all;
      expect(all, hasLength(2));
      expect(() => (all as List).add(FakePlugin('c')), throwsUnsupportedError);
    });
  });

  group('DevBuddyEngine plugin integration', () {
    test('plugins are registered and initialized with engine', () {
      final plugin = FakePlugin('test');
      final module = _FakeModule();
      final engine = DevBuddyEngine(modules: [module]);
      engine.registerPlugin(plugin);
      engine.initialize();

      expect(plugin.registered, isTrue);
      engine.dispose();
    });

    test('plugins appear in engine snapshot', () {
      final plugin = FakePlugin('custom');
      final module = _FakeModule();
      final engine = DevBuddyEngine(modules: [module]);
      engine.registerPlugin(plugin);
      engine.initialize();

      final snap = engine.snapshot();
      expect(snap['plugins'], containsPair('custom', {'id': 'custom'}));
      engine.dispose();
    });

    test('plugins are disposed when engine disposes', () {
      final plugin = FakePlugin('test');
      final module = _FakeModule();
      final engine = DevBuddyEngine(modules: [module]);
      engine.registerPlugin(plugin);
      engine.initialize();
      engine.dispose();

      expect(plugin.disposed, isTrue);
    });
  });
}

class _FakeModule extends DiagnosticModule {
  @override
  String get id => 'fake';
  @override
  String get displayName => 'Fake';
  @override
  Map<String, dynamic> get currentState => {};
  @override
  void initialize({
    required DevBuddyConfig config,
    required void Function(DevBuddyEvent) onEvent,
  }) {}
  @override
  void dispose() {}
}
