import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PerformanceMetadata', () {
    test('stores all fields', () {
      const meta = PerformanceMetadata(
        fps: 59.5,
        frameDurationMs: 17.2,
        consecutiveJanks: 3,
        jankCount: 15,
      );

      expect(meta.fps, equals(59.5));
      expect(meta.frameDurationMs, equals(17.2));
      expect(meta.consecutiveJanks, equals(3));
      expect(meta.jankCount, equals(15));
    });

    test('toJson() includes only non-null fields', () {
      const full = PerformanceMetadata(
        fps: 60.0,
        frameDurationMs: 16.6,
        consecutiveJanks: 0,
        jankCount: 5,
      );
      final json = full.toJson();
      expect(json['fps'], equals(60.0));
      expect(json['frame_duration_ms'], equals(16.6));
      expect(json['consecutive_janks'], equals(0));
      expect(json['jank_count'], equals(5));
    });

    test('toJson() omits null fields', () {
      const partial = PerformanceMetadata(fps: 30.0);
      final json = partial.toJson();
      expect(json.containsKey('fps'), isTrue);
      expect(json.containsKey('frame_duration_ms'), isFalse);
      expect(json.containsKey('consecutive_janks'), isFalse);
      expect(json.containsKey('jank_count'), isFalse);
    });

    test('toJson() returns empty map when all null', () {
      const empty = PerformanceMetadata();
      expect(empty.toJson(), isEmpty);
    });
  });

  group('NetworkEventMetadata', () {
    test('stores all fields', () {
      const meta = NetworkEventMetadata(
        url: 'https://api.example.com/users',
        method: 'GET',
        statusCode: 200,
        durationMs: 350,
        responseSize: 4096,
        contentType: 'application/json',
        errorMessage: null,
      );

      expect(meta.url, equals('https://api.example.com/users'));
      expect(meta.method, equals('GET'));
      expect(meta.statusCode, equals(200));
      expect(meta.durationMs, equals(350));
      expect(meta.responseSize, equals(4096));
      expect(meta.contentType, equals('application/json'));
      expect(meta.errorMessage, isNull);
    });

    test('toJson() includes only non-null fields', () {
      const meta = NetworkEventMetadata(
        url: 'https://api.test.com',
        method: 'POST',
        statusCode: 500,
        errorMessage: 'Internal Server Error',
      );
      final json = meta.toJson();

      expect(json['url'], equals('https://api.test.com'));
      expect(json['method'], equals('POST'));
      expect(json['status_code'], equals(500));
      expect(json['error'], equals('Internal Server Error'));
      expect(json.containsKey('duration_ms'), isFalse);
      expect(json.containsKey('response_size'), isFalse);
      expect(json.containsKey('content_type'), isFalse);
    });

    test('toJson() returns empty map when all null', () {
      const empty = NetworkEventMetadata();
      expect(empty.toJson(), isEmpty);
    });
  });

  group('RebuildMetadata', () {
    test('stores all fields', () {
      const meta = RebuildMetadata(
        rebuilds: {'MyWidget': 5, 'OtherWidget': 3},
        topRebuilders: [
          {'widget': 'MyWidget', 'count': 5},
          {'widget': 'OtherWidget', 'count': 3},
        ],
        totalRebuilds: 8,
      );

      expect(meta.rebuilds, hasLength(2));
      expect(meta.topRebuilders, hasLength(2));
      expect(meta.totalRebuilds, equals(8));
    });

    test('toJson() serializes correctly', () {
      const meta = RebuildMetadata(rebuilds: {'W': 10}, totalRebuilds: 10);
      final json = meta.toJson();

      expect(json['rebuilds'], equals({'W': 10}));
      expect(json['total_rebuilds'], equals(10));
      expect(json.containsKey('top_rebuilders'), isFalse);
    });

    test('toJson() returns empty map when all null', () {
      const empty = RebuildMetadata();
      expect(empty.toJson(), isEmpty);
    });
  });

  group('MemoryMetadata', () {
    test('stores all fields', () {
      const meta = MemoryMetadata(
        currentRss: 50000000,
        peakRss: 80000000,
        growthRateMbPerMinute: 2.5,
      );

      expect(meta.currentRss, equals(50000000));
      expect(meta.peakRss, equals(80000000));
      expect(meta.growthRateMbPerMinute, equals(2.5));
    });

    test('toJson() includes only non-null fields', () {
      const meta = MemoryMetadata(currentRss: 100000);
      final json = meta.toJson();

      expect(json['current_rss'], equals(100000));
      expect(json.containsKey('peak_rss'), isFalse);
      expect(json.containsKey('growth_rate_mb_per_minute'), isFalse);
    });

    test('toJson() returns empty map when all null', () {
      const empty = MemoryMetadata();
      expect(empty.toJson(), isEmpty);
    });
  });

  group('CorrelationMetadata', () {
    test('stores required rule and optional details', () {
      const meta = CorrelationMetadata(
        rule: 'jank_plus_rebuilds',
        details: {'widget': 'MyWidget', 'count': 42},
      );

      expect(meta.rule, equals('jank_plus_rebuilds'));
      expect(meta.details, containsPair('widget', 'MyWidget'));
    });

    test('toJson() always includes rule', () {
      const meta = CorrelationMetadata(rule: 'my_rule');
      final json = meta.toJson();

      expect(json['rule'], equals('my_rule'));
      expect(json.length, equals(1));
    });

    test('toJson() spreads details into top-level map', () {
      const meta = CorrelationMetadata(
        rule: 'test_rule',
        details: {'key1': 'value1', 'key2': 123},
      );
      final json = meta.toJson();

      expect(json['rule'], equals('test_rule'));
      expect(json['key1'], equals('value1'));
      expect(json['key2'], equals(123));
    });

    test('toJson() without details has only rule', () {
      const meta = CorrelationMetadata(rule: 'solo');
      final json = meta.toJson();
      expect(json, equals({'rule': 'solo'}));
    });
  });

  group('CustomMetadata', () {
    test('stores arbitrary map data', () {
      const meta = CustomMetadata({'custom_key': 'custom_value', 'number': 42});

      expect(meta.data['custom_key'], equals('custom_value'));
      expect(meta.data['number'], equals(42));
    });

    test('toJson() returns the data map directly', () {
      const meta = CustomMetadata({'a': 1, 'b': 'two'});
      final json = meta.toJson();

      expect(json, equals({'a': 1, 'b': 'two'}));
    });

    test('toJson() returns empty map for empty data', () {
      const meta = CustomMetadata({});
      expect(meta.toJson(), isEmpty);
    });
  });

  group('EventMetadata sealed class', () {
    test('all subtypes are EventMetadata', () {
      const perf = PerformanceMetadata(fps: 60.0);
      const network = NetworkEventMetadata(url: 'https://test.com');
      const rebuild = RebuildMetadata(totalRebuilds: 5);
      const memory = MemoryMetadata(currentRss: 1000);
      const correlation = CorrelationMetadata(rule: 'test');
      const custom = CustomMetadata({'key': 'value'});

      expect(perf, isA<EventMetadata>());
      expect(network, isA<EventMetadata>());
      expect(rebuild, isA<EventMetadata>());
      expect(memory, isA<EventMetadata>());
      expect(correlation, isA<EventMetadata>());
      expect(custom, isA<EventMetadata>());
    });

    test('switch exhaustiveness on sealed class', () {
      // This verifies that the sealed class is properly sealed
      // by performing an exhaustive switch
      const EventMetadata meta = PerformanceMetadata(fps: 60.0);
      final label = switch (meta) {
        PerformanceMetadata() => 'performance',
        NetworkEventMetadata() => 'network',
        RebuildMetadata() => 'rebuild',
        MemoryMetadata() => 'memory',
        CorrelationMetadata() => 'correlation',
        CustomMetadata() => 'custom',
      };
      expect(label, equals('performance'));
    });
  });

  group('DevBuddyEvent with typed metadata', () {
    test('event with PerformanceMetadata via typedMetadata', () {
      final event = DevBuddyEvent(
        module: 'performance',
        severity: Severity.warning,
        title: 'Jank detected',
        description: 'Frame took too long',
        suggestions: ['Optimize widget tree'],
        typedMetadata: const PerformanceMetadata(fps: 45.0, jankCount: 3),
      );

      expect(event.typedMetadata, isA<PerformanceMetadata>());
      final meta = event.typedMetadata! as PerformanceMetadata;
      expect(meta.fps, equals(45.0));
      expect(meta.jankCount, equals(3));

      // Legacy accessor should return the JSON form
      expect(event.metadata, isNotNull);
      expect(event.metadata!['fps'], equals(45.0));
      expect(event.metadata!['jank_count'], equals(3));
    });

    test('event with NetworkEventMetadata via typedMetadata', () {
      final event = DevBuddyEvent(
        module: 'network',
        severity: Severity.info,
        title: 'Request completed',
        description: 'GET /users',
        suggestions: [],
        typedMetadata: const NetworkEventMetadata(
          url: 'https://api.test.com/users',
          method: 'GET',
          statusCode: 200,
          durationMs: 150,
        ),
      );

      expect(event.typedMetadata, isA<NetworkEventMetadata>());
      expect(event.metadata!['url'], equals('https://api.test.com/users'));
      expect(event.metadata!['status_code'], equals(200));
    });

    test('event with legacy Map metadata wraps in CustomMetadata', () {
      final event = DevBuddyEvent(
        module: 'test',
        severity: Severity.info,
        title: 'Legacy event',
        description: 'Uses old-style metadata',
        suggestions: [],
        metadata: {'key': 'value', 'count': 42},
      );

      // typedMetadata should be CustomMetadata wrapping the map
      expect(event.typedMetadata, isA<CustomMetadata>());
      final custom = event.typedMetadata! as CustomMetadata;
      expect(custom.data['key'], equals('value'));
      expect(custom.data['count'], equals(42));

      // Legacy accessor should still work
      expect(event.metadata, isNotNull);
      expect(event.metadata!['key'], equals('value'));
    });

    test('typedMetadata takes precedence over metadata map', () {
      // When both are provided, typedMetadata wins
      final event = DevBuddyEvent(
        module: 'test',
        severity: Severity.info,
        title: 'Both provided',
        description: 'typedMetadata should win',
        suggestions: [],
        metadata: {'old': 'ignored'},
        typedMetadata: const PerformanceMetadata(fps: 30.0),
      );

      expect(event.typedMetadata, isA<PerformanceMetadata>());
      expect(event.metadata!['fps'], equals(30.0));
      expect(event.metadata!.containsKey('old'), isFalse);
    });

    test('event with null metadata has null typedMetadata', () {
      final event = DevBuddyEvent(
        module: 'test',
        severity: Severity.info,
        title: 'No metadata',
        description: 'desc',
        suggestions: [],
      );

      expect(event.typedMetadata, isNull);
      expect(event.metadata, isNull);
    });

    test('toJson() includes typed metadata under metadata key', () {
      final event = DevBuddyEvent(
        module: 'memory',
        severity: Severity.warning,
        title: 'High memory',
        description: 'desc',
        suggestions: [],
        typedMetadata: const MemoryMetadata(
          currentRss: 50000000,
          peakRss: 80000000,
        ),
      );

      final json = event.toJson();
      expect(json['metadata'], isA<Map>());
      expect(json['metadata']['current_rss'], equals(50000000));
      expect(json['metadata']['peak_rss'], equals(80000000));
    });

    test('toJson() omits metadata key when typedMetadata is null', () {
      final event = DevBuddyEvent(
        module: 'test',
        severity: Severity.info,
        title: 'No meta',
        description: 'desc',
        suggestions: [],
      );

      final json = event.toJson();
      expect(json.containsKey('metadata'), isFalse);
    });

    test('legacy Map metadata is unmodifiable after construction', () {
      final event = DevBuddyEvent(
        module: 'test',
        severity: Severity.info,
        title: 'Immutable test',
        description: 'desc',
        suggestions: [],
        metadata: {'mutable': 'data'},
      );

      final custom = event.typedMetadata! as CustomMetadata;
      expect(
        () => custom.data['new_key'] = 'fail',
        throwsUnsupportedError,
      );
    });

    test('copyWith preserves typedMetadata', () {
      final original = DevBuddyEvent(
        module: 'performance',
        severity: Severity.info,
        title: 'Original',
        description: 'desc',
        suggestions: [],
        typedMetadata: const PerformanceMetadata(fps: 60.0),
      );

      final copy = original.copyWith(title: 'Copied');

      expect(copy.title, equals('Copied'));
      expect(copy.typedMetadata, isA<PerformanceMetadata>());
      expect((copy.typedMetadata! as PerformanceMetadata).fps, equals(60.0));
    });

    test('copyWith can replace typedMetadata', () {
      final original = DevBuddyEvent(
        module: 'test',
        severity: Severity.info,
        title: 'Original',
        description: 'desc',
        suggestions: [],
        typedMetadata: const PerformanceMetadata(fps: 60.0),
      );

      final copy = original.copyWith(
        typedMetadata: const MemoryMetadata(currentRss: 1000),
      );

      expect(copy.typedMetadata, isA<MemoryMetadata>());
      expect((copy.typedMetadata! as MemoryMetadata).currentRss, equals(1000));
    });
  });

  group('Backwards compatibility', () {
    test('Map constructor creates CustomMetadata internally', () {
      final event = DevBuddyEvent(
        module: 'legacy',
        severity: Severity.info,
        title: 'Old API',
        description: 'desc',
        suggestions: ['update code'],
        metadata: {
          'version': 1,
          'data': [1, 2, 3],
        },
      );

      expect(event.typedMetadata, isA<CustomMetadata>());
      expect(event.metadata!['version'], equals(1));
      expect(event.metadata!['data'], equals([1, 2, 3]));
    });

    test('metadata getter returns toJson() for all typed metadata', () {
      final events = [
        DevBuddyEvent(
          module: 'perf',
          severity: Severity.info,
          title: 't',
          description: 'd',
          suggestions: [],
          typedMetadata: const PerformanceMetadata(fps: 60.0),
        ),
        DevBuddyEvent(
          module: 'net',
          severity: Severity.info,
          title: 't',
          description: 'd',
          suggestions: [],
          typedMetadata: const NetworkEventMetadata(statusCode: 200),
        ),
        DevBuddyEvent(
          module: 'rebuild',
          severity: Severity.info,
          title: 't',
          description: 'd',
          suggestions: [],
          typedMetadata: const RebuildMetadata(totalRebuilds: 5),
        ),
        DevBuddyEvent(
          module: 'mem',
          severity: Severity.info,
          title: 't',
          description: 'd',
          suggestions: [],
          typedMetadata: const MemoryMetadata(currentRss: 1024),
        ),
        DevBuddyEvent(
          module: 'corr',
          severity: Severity.info,
          title: 't',
          description: 'd',
          suggestions: [],
          typedMetadata: const CorrelationMetadata(rule: 'r1'),
        ),
      ];

      for (final event in events) {
        // metadata getter should never be null when typedMetadata is set
        expect(event.metadata, isNotNull);
        expect(event.metadata, isA<Map<String, dynamic>>());
      }
    });

    test('existing code using Map metadata continues to work', () {
      // Simulate existing code patterns that use metadata as Map
      final event = DevBuddyEvent(
        module: 'network',
        severity: Severity.warning,
        title: 'Slow request',
        description: 'desc',
        suggestions: [],
        metadata: {'url': 'https://api.test.com', 'status_code': 401},
      );

      // Pattern used by CorrelationEngine rules
      final statusCode = event.metadata?['status_code'];
      expect(statusCode, equals(401));

      final url = event.metadata?['url'];
      expect(url, equals('https://api.test.com'));
    });
  });
}
