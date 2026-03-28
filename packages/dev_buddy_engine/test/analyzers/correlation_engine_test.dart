import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

DevBuddyEvent _event({
  String module = 'test',
  Severity severity = Severity.info,
  String title = 'Test',
  Map<String, dynamic>? metadata,
}) =>
    DevBuddyEvent(
      module: module,
      severity: severity,
      title: title,
      description: 'desc',
      suggestions: ['fix'],
      metadata: metadata,
    );

void main() {
  group('CorrelationEngine', () {
    late CorrelationEngine engine;

    setUp(() => engine = CorrelationEngine());

    test('returns empty when no rules match', () {
      final events = [_event(module: 'performance', severity: Severity.info)];
      expect(engine.evaluate(events), isEmpty);
    });

    test('detects jank + rebuild correlation', () {
      final events = [
        _event(
          module: 'performance',
          severity: Severity.warning,
          title: 'UI Jank',
        ),
        _event(
          module: 'rebuilds',
          severity: Severity.warning,
          title: 'Excessive Rebuilds',
          metadata: {
            'top_rebuilders': [
              {'widget': 'ProfileAvatar', 'count': 47},
            ],
          },
        ),
      ];

      final insights = engine.evaluate(events);
      expect(insights, hasLength(1));
      expect(insights.first.module, 'correlation');
      expect(insights.first.severity, Severity.critical);
      expect(insights.first.title, contains('Rebuilds'));
      expect(insights.first.description, contains('ProfileAvatar'));
    });

    test('detects repeated auth failures', () {
      final events = List.generate(
        4,
        (_) => _event(
          module: 'network',
          severity: Severity.critical,
          metadata: {'status_code': 401},
        ),
      );

      final insights = engine.evaluate(events);
      expect(insights, hasLength(1));
      expect(insights.first.title, contains('Token Refresh'));
      expect(insights.first.metadata?['count'], 4);
    });

    test('detects memory spike + large response', () {
      final events = [
        _event(module: 'memory', severity: Severity.warning),
        _event(
          module: 'network',
          severity: Severity.info,
          metadata: {
            'response_size': 600 * 1024, // 600KB
            'url': '/api/images',
          },
        ),
      ];

      final insights = engine.evaluate(events);
      expect(insights, hasLength(1));
      expect(insights.first.title, contains('Large Resource'));
    });

    test('does not fire same rule twice', () {
      final events = [
        _event(module: 'performance', severity: Severity.warning),
        _event(
          module: 'rebuilds',
          severity: Severity.warning,
          metadata: {'top_rebuilders': []},
        ),
      ];

      engine.evaluate(events); // First fire
      final second = engine.evaluate(events); // Should not fire again
      expect(second, isEmpty);
    });

    test('reset allows rules to fire again', () {
      final events = [
        _event(module: 'performance', severity: Severity.warning),
        _event(
          module: 'rebuilds',
          severity: Severity.warning,
          metadata: {'top_rebuilders': []},
        ),
      ];

      engine.evaluate(events);
      engine.reset();
      final again = engine.evaluate(events);
      expect(again, hasLength(1));
    });

    test('has 5 default rules', () {
      expect(engine.ruleCount, 5);
    });

    test('custom rules can be provided', () {
      final custom = CorrelationEngine(rules: [
        CorrelationRule(
          id: 'custom',
          name: 'Custom Rule',
          matches: (events) => events.length > 2,
          synthesize: (_) => _event(module: 'correlation', title: 'Custom Insight'),
        ),
      ]);

      final events = [_event(), _event(), _event()];
      final insights = custom.evaluate(events);
      expect(insights, hasLength(1));
      expect(insights.first.title, 'Custom Insight');
    });
  });
}
