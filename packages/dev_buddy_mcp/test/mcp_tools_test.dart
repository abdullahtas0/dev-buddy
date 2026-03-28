import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:dev_buddy_mcp/dev_buddy_mcp.dart';
import 'package:test/test.dart';

class _FakeModule extends DiagnosticModule {
  @override
  String get id => 'fake';
  @override
  String get displayName => 'Fake';
  @override
  Map<String, dynamic> get currentState => {'active': true};

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

  void emit({
    Severity severity = Severity.warning,
    String module = 'fake',
    String title = 'Test Event',
  }) {
    _onEvent(
      DevBuddyEvent(
        module: module,
        severity: severity,
        title: title,
        description: 'Test description',
        suggestions: ['Fix it', 'Try again'],
      ),
    );
  }
}

void main() {
  group('McpTools', () {
    late DevBuddyEngine engine;
    late _FakeModule module;
    late McpTools tools;

    setUp(() {
      module = _FakeModule();
      engine = DevBuddyEngine(
        modules: [module],
        config: const DevBuddyConfig(maxEvents: 50),
      );
      engine.initialize();
      tools = McpTools(engine: engine);
    });

    tearDown(() => engine.dispose());

    test('diagnostics returns compact snapshot', () {
      module.emit();
      engine.flushForTesting();

      final result = tools.diagnostics({});
      expect(result['overall_severity'], isA<String>());
      expect(result['event_count'], 1);
      expect(result['top_issues'], hasLength(1));
    });

    test('suggest returns suggestions from events', () {
      module.emit();
      engine.flushForTesting();

      final result = tools.suggest({});
      expect(result['suggestions'], isA<List>());
      expect((result['suggestions'] as List).first['fix'], 'Fix it');
    });

    test('searchEvents filters by module', () {
      module.emit(module: 'performance', title: 'Jank');
      module.emit(module: 'network', title: 'Slow');
      engine.flushForTesting();

      final result = tools.searchEvents({'module': 'performance'});
      expect(result['total'], 1);
      expect((result['results'] as List).first['title'], contains('Jank'));
    });

    test('searchEvents filters by severity', () {
      module.emit(severity: Severity.info, title: 'Info');
      module.emit(severity: Severity.critical, title: 'Critical');
      engine.flushForTesting();

      final result = tools.searchEvents({'severity': 'critical'});
      expect(result['total'], 1);
    });

    test('searchEvents filters by query text', () {
      module.emit(title: 'Memory Leak Detected');
      module.emit(title: 'Network Slow');
      engine.flushForTesting();

      final result = tools.searchEvents({'query': 'memory'});
      expect(result['total'], 1);
    });

    test('detail returns full event info', () {
      module.emit(title: 'Detailed Event');
      engine.flushForTesting();

      final result = tools.detail({'index': 0});
      expect(result['title'], contains('Detailed Event'));
      expect(result['suggestions'], hasLength(2));
    });

    test('detail returns error for invalid index', () {
      final result = tools.detail({'index': 999});
      expect(result['error'], contains('out of range'));
    });

    test('performance returns jank summary', () {
      module.emit(module: 'performance', title: 'Jank');
      engine.flushForTesting();

      final result = tools.performance({});
      expect(result['jank_event_count'], 1);
    });

    test('errors returns error summary', () {
      module.emit(module: 'errors', title: 'Null Check');
      engine.flushForTesting();

      final result = tools.errors({});
      expect(result['error_count'], 1);
    });

    test('tools map has all 9 tools registered', () {
      expect(tools.tools.length, 9);
    });

    test('toolDefinitions has matching count', () {
      expect(tools.toolDefinitions.length, 9);
    });

    test('sanitizer redacts sensitive headers', () {
      const sanitizer = DataSanitizer(level: SanitizationLevel.moderate);
      final headers = {
        'Authorization': 'Bearer secret123',
        'Content-Type': 'application/json',
      };
      final sanitized = sanitizer.sanitizeHeaders(headers);

      expect(sanitized['Authorization'], '[REDACTED]');
      expect(sanitized['Content-Type'], 'application/json');
    });

    test('sanitizer detects email PII', () {
      const sanitizer = DataSanitizer(level: SanitizationLevel.moderate);
      final result = sanitizer.sanitizeValue('Contact: user@example.com');
      expect(result, contains('[EMAIL]'));
      expect(result, isNot(contains('user@example.com')));
    });

    test('sanitizer truncates long bodies', () {
      const sanitizer = DataSanitizer(maxBodyLength: 50);
      final longBody = 'x' * 100;
      final result = sanitizer.sanitizeBody(longBody);

      expect(result, contains('[TRUNCATED'));
      expect(result.length, lessThan(100));
    });
  });
}
