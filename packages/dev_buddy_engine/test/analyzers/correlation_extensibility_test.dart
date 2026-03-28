import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

DevBuddyEvent _event({
  String module = 'test',
  Severity severity = Severity.info,
  String title = 'Test Event',
  Map<String, dynamic>? metadata,
}) => DevBuddyEvent(
  module: module,
  severity: severity,
  title: title,
  description: 'desc',
  suggestions: ['fix it'],
  metadata: metadata,
);

CorrelationRule _customRule({
  required String id,
  String name = 'Custom Rule',
  bool Function(List<DevBuddyEvent>)? matches,
  DevBuddyEvent Function(List<DevBuddyEvent>)? synthesize,
}) => CorrelationRule(
  id: id,
  name: name,
  matches: matches ?? (_) => false,
  synthesize:
      synthesize ?? (_) => _event(module: 'correlation', title: 'Custom: $id'),
);

void main() {
  group('CorrelationEngine.addRule()', () {
    test('adds a rule and increases rule count', () {
      final engine = CorrelationEngine(rules: []);
      expect(engine.ruleCount, equals(0));

      engine.addRule(_customRule(id: 'custom_1'));
      expect(engine.ruleCount, equals(1));
    });

    test('added rule is included in rules getter', () {
      final engine = CorrelationEngine(rules: []);
      final rule = _customRule(id: 'new_rule', name: 'New Rule');
      engine.addRule(rule);

      expect(engine.rules.any((r) => r.id == 'new_rule'), isTrue);
      expect(engine.rules.first.name, equals('New Rule'));
    });

    test('added rule is evaluated by evaluate()', () {
      final engine = CorrelationEngine(rules: []);

      engine.addRule(
        CorrelationRule(
          id: 'always_fires',
          name: 'Always Fires',
          matches: (_) => true,
          synthesize: (_) =>
              _event(module: 'correlation', title: 'Custom correlation fired'),
        ),
      );

      final results = engine.evaluate([_event()]);
      expect(results, hasLength(1));
      expect(results.first.title, equals('Custom correlation fired'));
    });

    test('throws ArgumentError on duplicate id', () {
      final engine = CorrelationEngine(rules: []);
      engine.addRule(_customRule(id: 'unique'));

      expect(
        () => engine.addRule(_customRule(id: 'unique')),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('unique'),
          ),
        ),
      );
    });

    test('throws on duplicate id even with different name', () {
      final engine = CorrelationEngine(rules: []);
      engine.addRule(_customRule(id: 'dup', name: 'First'));

      expect(
        () => engine.addRule(_customRule(id: 'dup', name: 'Second')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('allows adding rule with id of previously removed rule', () {
      final engine = CorrelationEngine(rules: []);
      engine.addRule(_customRule(id: 'recyclable'));
      engine.removeRule('recyclable');

      // Should not throw — id is no longer registered
      expect(
        () => engine.addRule(_customRule(id: 'recyclable')),
        returnsNormally,
      );
      expect(engine.ruleCount, equals(1));
    });

    test('multiple rules can be added sequentially', () {
      final engine = CorrelationEngine(rules: []);

      for (var i = 0; i < 10; i++) {
        engine.addRule(_customRule(id: 'rule_$i'));
      }

      expect(engine.ruleCount, equals(10));
      expect(
        engine.rules.map((r) => r.id),
        containsAll(['rule_0', 'rule_4', 'rule_9']),
      );
    });
  });

  group('CorrelationEngine.removeRule()', () {
    test('returns true when rule exists and is removed', () {
      final engine = CorrelationEngine(rules: []);
      engine.addRule(_customRule(id: 'removable'));

      final removed = engine.removeRule('removable');
      expect(removed, isTrue);
      expect(engine.ruleCount, equals(0));
    });

    test('returns false when rule does not exist', () {
      final engine = CorrelationEngine(rules: []);
      final removed = engine.removeRule('nonexistent');
      expect(removed, isFalse);
    });

    test('removed rule is no longer evaluated', () {
      final engine = CorrelationEngine(rules: []);

      engine.addRule(
        CorrelationRule(
          id: 'to_remove',
          name: 'To Remove',
          matches: (_) => true,
          synthesize: (_) =>
              _event(module: 'correlation', title: 'Should not appear'),
        ),
      );

      // Verify it fires before removal
      var results = engine.evaluate([_event()]);
      expect(results, hasLength(1));

      engine.reset(); // Reset fired tracking so we can test removal
      engine.removeRule('to_remove');

      results = engine.evaluate([_event()]);
      expect(results, isEmpty);
    });

    test('removing a rule also clears its fired status', () {
      final engine = CorrelationEngine(rules: []);

      engine.addRule(
        CorrelationRule(
          id: 'fire_and_remove',
          name: 'Fire and Remove',
          matches: (_) => true,
          synthesize: (_) => _event(module: 'correlation', title: 'Fired'),
        ),
      );

      // Fire the rule
      engine.evaluate([_event()]);

      // Remove and re-add
      engine.removeRule('fire_and_remove');
      engine.addRule(
        CorrelationRule(
          id: 'fire_and_remove',
          name: 'Fire and Remove v2',
          matches: (_) => true,
          synthesize: (_) =>
              _event(module: 'correlation', title: 'Fired again'),
        ),
      );

      // Should fire again since fired status was cleared
      final results = engine.evaluate([_event()]);
      expect(results, hasLength(1));
      expect(results.first.title, equals('Fired again'));
    });

    test('removing one rule does not affect others', () {
      final engine = CorrelationEngine(rules: []);

      engine.addRule(
        CorrelationRule(
          id: 'keeper',
          name: 'Keeper',
          matches: (_) => true,
          synthesize: (_) => _event(module: 'correlation', title: 'Kept'),
        ),
      );
      engine.addRule(_customRule(id: 'goner'));

      engine.removeRule('goner');

      expect(engine.ruleCount, equals(1));
      expect(engine.rules.first.id, equals('keeper'));

      final results = engine.evaluate([_event()]);
      expect(results, hasLength(1));
      expect(results.first.title, equals('Kept'));
    });

    test('can remove a default rule', () {
      final engine = CorrelationEngine(); // includes default rules
      final initialCount = engine.ruleCount;

      final removed = engine.removeRule('jank_plus_rebuilds');
      expect(removed, isTrue);
      expect(engine.ruleCount, equals(initialCount - 1));
      expect(engine.rules.any((r) => r.id == 'jank_plus_rebuilds'), isFalse);
    });
  });

  group('CorrelationEngine.replaceRules()', () {
    test('replaces all rules with new set', () {
      final engine = CorrelationEngine(); // has default rules
      expect(engine.ruleCount, greaterThan(0));

      final newRules = [_customRule(id: 'new_1'), _customRule(id: 'new_2')];

      engine.replaceRules(newRules);

      expect(engine.ruleCount, equals(2));
      expect(engine.rules.map((r) => r.id), containsAll(['new_1', 'new_2']));
    });

    test('replaceRules with empty list removes all rules', () {
      final engine = CorrelationEngine();
      engine.replaceRules([]);

      expect(engine.ruleCount, equals(0));
      expect(engine.rules, isEmpty);
    });

    test('replaceRules resets fired tracking', () {
      final engine = CorrelationEngine(rules: []);

      final alwaysFires = CorrelationRule(
        id: 'persistent',
        name: 'Persistent',
        matches: (_) => true,
        synthesize: (_) => _event(module: 'correlation', title: 'Fires'),
      );

      engine.addRule(alwaysFires);
      engine.evaluate([_event()]); // fires, marks as fired

      // Replace with the same rule — fired status should be reset
      engine.replaceRules([alwaysFires]);

      final results = engine.evaluate([_event()]);
      expect(
        results,
        hasLength(1),
        reason: 'Rule should fire after replaceRules resets fired tracking',
      );
    });

    test('replaceRules does not share state with original list', () {
      final engine = CorrelationEngine(rules: []);
      final mutableList = [_customRule(id: 'original')];

      engine.replaceRules(mutableList);
      mutableList.add(_customRule(id: 'sneaky'));

      // Engine should not be affected by external mutation
      expect(engine.ruleCount, equals(1));
    });

    test('old rules are not evaluated after replacement', () {
      final engine = CorrelationEngine(rules: []);

      engine.addRule(
        CorrelationRule(
          id: 'old_rule',
          name: 'Old',
          matches: (_) => true,
          synthesize: (_) => _event(module: 'correlation', title: 'Old fired'),
        ),
      );

      engine.replaceRules([
        CorrelationRule(
          id: 'new_rule',
          name: 'New',
          matches: (_) => true,
          synthesize: (_) => _event(module: 'correlation', title: 'New fired'),
        ),
      ]);

      final results = engine.evaluate([_event()]);
      expect(results, hasLength(1));
      expect(results.first.title, equals('New fired'));
    });
  });

  group('CorrelationEngine.rules getter', () {
    test('returns unmodifiable view', () {
      final engine = CorrelationEngine();
      final rules = engine.rules;

      expect(
        () => rules.add(_customRule(id: 'sneaky')),
        throwsUnsupportedError,
      );
    });

    test('returns unmodifiable view even when empty', () {
      final engine = CorrelationEngine(rules: []);
      final rules = engine.rules;

      expect(rules, isEmpty);
      expect(
        () => rules.add(_customRule(id: 'sneaky')),
        throwsUnsupportedError,
      );
    });

    test('reflects changes after addRule', () {
      final engine = CorrelationEngine(rules: []);
      engine.addRule(_customRule(id: 'added'));

      final rules = engine.rules;
      expect(rules, hasLength(1));
      expect(rules.first.id, equals('added'));
    });

    test('reflects changes after removeRule', () {
      final engine = CorrelationEngine(rules: []);
      engine.addRule(_customRule(id: 'a'));
      engine.addRule(_customRule(id: 'b'));
      engine.removeRule('a');

      final rules = engine.rules;
      expect(rules, hasLength(1));
      expect(rules.first.id, equals('b'));
    });

    test('reflects changes after replaceRules', () {
      final engine = CorrelationEngine();
      engine.replaceRules([_customRule(id: 'replaced')]);

      final rules = engine.rules;
      expect(rules, hasLength(1));
      expect(rules.first.id, equals('replaced'));
    });

    test('default engine has all 5 built-in rules', () {
      final engine = CorrelationEngine();
      final ruleIds = engine.rules.map((r) => r.id).toSet();

      expect(
        ruleIds,
        containsAll([
          'jank_plus_rebuilds',
          'memory_growth_navigation',
          'slow_network_jank',
          'repeated_auth_failures',
          'memory_spike_large_response',
        ]),
      );
      expect(engine.ruleCount, equals(5));
    });
  });

  group('CorrelationEngine custom rule evaluation', () {
    test('custom rule that counts specific events', () {
      final engine = CorrelationEngine(rules: []);

      engine.addRule(
        CorrelationRule(
          id: 'too_many_errors',
          name: 'Too Many Errors',
          matches: (events) {
            return events
                    .where((e) => e.severity == Severity.critical)
                    .length >=
                5;
          },
          synthesize: (events) {
            final errorCount = events
                .where((e) => e.severity == Severity.critical)
                .length;
            return DevBuddyEvent(
              module: 'correlation',
              severity: Severity.critical,
              title: 'Error Storm Detected',
              description: '$errorCount critical errors in recent history',
              suggestions: ['Check error logs', 'Restart services'],
              typedMetadata: CorrelationMetadata(
                rule: 'too_many_errors',
                details: {'error_count': errorCount},
              ),
            );
          },
        ),
      );

      // Not enough errors — should not fire
      final fewErrors = List.generate(
        3,
        (i) => _event(severity: Severity.critical),
      );
      expect(engine.evaluate(fewErrors), isEmpty);

      // Enough errors — should fire
      final manyErrors = List.generate(
        10,
        (i) => _event(severity: Severity.critical),
      );
      final results = engine.evaluate(manyErrors);
      expect(results, hasLength(1));
      expect(results.first.title, equals('Error Storm Detected'));
      expect(results.first.typedMetadata, isA<CorrelationMetadata>());
    });

    test('custom rule with module-specific matching', () {
      final engine = CorrelationEngine(rules: []);

      engine.addRule(
        CorrelationRule(
          id: 'memory_plus_network',
          name: 'Memory + Network',
          matches: (events) {
            final hasMemory = events.any((e) => e.module == 'memory');
            final hasNetwork = events.any((e) => e.module == 'network');
            return hasMemory && hasNetwork;
          },
          synthesize: (_) => _event(
            module: 'correlation',
            title: 'Memory and Network correlated',
          ),
        ),
      );

      // Only memory events
      expect(engine.evaluate([_event(module: 'memory')]), isEmpty);

      engine.reset();

      // Both memory and network events
      final results = engine.evaluate([
        _event(module: 'memory'),
        _event(module: 'network'),
      ]);
      expect(results, hasLength(1));
    });
  });
}
