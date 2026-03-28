import 'package:dev_buddy_engine/dev_buddy_engine.dart';

/// Defines all MCP tools that DevBuddy exposes to AI IDEs.
///
/// Each tool takes a parameters map and returns a JSON-serializable result.
/// The MCP transport layer (stdin/stdout JSON-RPC) calls these handlers.
///
/// Tool design follows Design Review v2 principles:
/// - **Summary-first:** Default responses are compact (< 2KB)
/// - **Query-specific:** AI asks for what it needs, not "fetch all"
/// - **Lazy detail:** Full data via drill-down tools
/// - **Sanitized:** PII scrubbed before any data leaves
class McpTools {
  final DevBuddyEngine engine;
  final DataSanitizer sanitizer;

  McpTools({
    required this.engine,
    DataSanitizer? sanitizer,
  }) : sanitizer = sanitizer ?? const DataSanitizer();

  /// Registry of tool name → handler.
  Map<String, Map<String, dynamic> Function(Map<String, dynamic>)> get tools => {
        'dev_buddy/diagnostics': diagnostics,
        'dev_buddy/suggest': suggest,
        'dev_buddy/search_events': searchEvents,
        'dev_buddy/search_network': searchNetwork,
        'dev_buddy/search_state': searchState,
        'dev_buddy/detail': detail,
        'dev_buddy/performance': performance,
        'dev_buddy/memory': memory,
        'dev_buddy/errors': errors,
      };

  /// Tool definitions for MCP registration (name, description, parameters).
  List<Map<String, dynamic>> get toolDefinitions => [
        {
          'name': 'dev_buddy/diagnostics',
          'description': 'Get current diagnostic snapshot: FPS, memory, severity, top issues',
          'inputSchema': {'type': 'object', 'properties': {}},
        },
        {
          'name': 'dev_buddy/suggest',
          'description': 'Get AI-friendly compound suggestions based on correlated signals',
          'inputSchema': {'type': 'object', 'properties': {}},
        },
        {
          'name': 'dev_buddy/search_events',
          'description': 'Search diagnostic events by query, module, severity, or time range',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'query': {'type': 'string', 'description': 'Free text search in event titles/descriptions'},
              'module': {'type': 'string', 'description': 'Filter by module id (performance, network, errors, memory, rebuilds)'},
              'severity': {'type': 'string', 'description': 'Minimum severity: info, warning, critical'},
              'limit': {'type': 'integer', 'description': 'Max results (default: 5)'},
            },
          },
        },
        {
          'name': 'dev_buddy/search_network',
          'description': 'Search network requests by URL pattern, status code, or duration',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'urlPattern': {'type': 'string', 'description': 'URL substring to match'},
              'statusCode': {'type': 'integer', 'description': 'Filter by status code'},
              'minDurationMs': {'type': 'integer', 'description': 'Minimum duration in ms'},
              'limit': {'type': 'integer', 'description': 'Max results (default: 5)'},
            },
          },
        },
        {
          'name': 'dev_buddy/search_state',
          'description': 'Search state change history by source provider or action',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'source': {'type': 'string', 'description': 'State source (e.g., riverpod:counterProvider)'},
              'action': {'type': 'string', 'description': 'Action/event name'},
              'limit': {'type': 'integer', 'description': 'Max results (default: 10)'},
            },
          },
        },
        {
          'name': 'dev_buddy/detail',
          'description': 'Get full details of a specific event by index',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'index': {'type': 'integer', 'description': 'Event index in history (0 = newest)'},
            },
            'required': ['index'],
          },
        },
        {
          'name': 'dev_buddy/performance',
          'description': 'Get frame timing and jank analysis summary',
          'inputSchema': {'type': 'object', 'properties': {}},
        },
        {
          'name': 'dev_buddy/memory',
          'description': 'Get memory usage trend and leak heuristic result',
          'inputSchema': {'type': 'object', 'properties': {}},
        },
        {
          'name': 'dev_buddy/errors',
          'description': 'Get error catalog matches with fix suggestions',
          'inputSchema': {'type': 'object', 'properties': {}},
        },
      ];

  // === Tool Handlers ===

  /// Compact diagnostic snapshot — always the first tool AI should call.
  Map<String, dynamic> diagnostics(Map<String, dynamic> params) {
    final snap = engine.snapshot();
    return {
      'overall_severity': snap['overall_severity'],
      'event_count': snap['event_count'],
      'top_issues': (engine.eventBus.history.take(3).toList())
          .map((e) => {
                'module': e.module,
                'severity': e.severity.name,
                'title': sanitizer.sanitizeValue(e.title),
              })
          .toList(),
      'state_store': snap['state_store'],
    };
  }

  /// AI-friendly suggestions from recent events.
  Map<String, dynamic> suggest(Map<String, dynamic> params) {
    final events = engine.eventBus.history.take(10).toList();
    final suggestions = <Map<String, dynamic>>[];

    for (final event in events) {
      if (event.suggestions.isNotEmpty) {
        suggestions.add({
          'issue': sanitizer.sanitizeValue(event.title),
          'severity': event.severity.name,
          'fix': event.suggestions.first,
        });
      }
    }

    return {'suggestions': suggestions.take(5).toList()};
  }

  /// Search events with filters.
  Map<String, dynamic> searchEvents(Map<String, dynamic> params) {
    final query = params['query'] as String?;
    final module = params['module'] as String?;
    final severityStr = params['severity'] as String?;
    final limit = (params['limit'] as int?) ?? 5;

    var results = engine.eventBus.history.toList();

    if (module != null) {
      results = results.where((e) => e.module == module).toList();
    }
    if (severityStr != null) {
      final minSev = Severity.values.firstWhere(
        (s) => s.name == severityStr,
        orElse: () => Severity.info,
      );
      results = results.where((e) => e.severity.isAtLeast(minSev)).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q))
          .toList();
    }

    return {
      'total': results.length,
      'results': results.take(limit).map((e) => {
            'module': e.module,
            'severity': e.severity.name,
            'title': sanitizer.sanitizeValue(e.title),
            'description': sanitizer.sanitizeBody(e.description),
            'timestamp': e.timestamp.toIso8601String(),
          }).toList(),
    };
  }

  /// Search network requests.
  Map<String, dynamic> searchNetwork(Map<String, dynamic> params) {
    final urlPattern = params['urlPattern'] as String?;
    final statusCode = params['statusCode'] as int?;
    final minDurationMs = params['minDurationMs'] as int?;
    final limit = (params['limit'] as int?) ?? 5;

    var results = engine.eventBus.historyFor('network');

    if (urlPattern != null) {
      results = results
          .where((e) => (e.metadata?['url'] ?? '').toString().contains(urlPattern))
          .toList();
    }
    if (statusCode != null) {
      results = results
          .where((e) => e.metadata?['status_code'] == statusCode)
          .toList();
    }
    if (minDurationMs != null) {
      results = results
          .where((e) => (e.metadata?['duration_ms'] ?? 0) >= minDurationMs)
          .toList();
    }

    return {
      'total': results.length,
      'results': results.take(limit).map((e) => {
            'title': sanitizer.sanitizeValue(e.title),
            'severity': e.severity.name,
            'timestamp': e.timestamp.toIso8601String(),
          }).toList(),
    };
  }

  /// Search state history.
  Map<String, dynamic> searchState(Map<String, dynamic> params) {
    final source = params['source'] as String?;
    final action = params['action'] as String?;
    final limit = (params['limit'] as int?) ?? 10;

    var results = engine.stateStore.history;

    if (source != null) {
      results = results.where((s) => s.source.contains(source)).toList();
    }
    if (action != null) {
      results = results.where((s) => s.action == action).toList();
    }

    return {
      'total': results.length,
      'results': results.take(limit).map((s) => {
            'version': s.version,
            'source': s.source,
            'action': s.action,
            'timestamp': s.timestamp.toIso8601String(),
            'is_anchor': s.isAnchor,
            if (s.serializedDiff != null)
              'diff': sanitizer.sanitizeBody(s.serializedDiff!),
          }).toList(),
    };
  }

  /// Full event detail by index.
  Map<String, dynamic> detail(Map<String, dynamic> params) {
    final index = params['index'] as int? ?? 0;
    final history = engine.eventBus.history;

    if (index < 0 || index >= history.length) {
      return {'error': 'Index out of range. History has ${history.length} events.'};
    }

    final event = history[index];
    return {
      'module': event.module,
      'severity': event.severity.name,
      'title': sanitizer.sanitizeValue(event.title),
      'description': sanitizer.sanitizeBody(event.description),
      'suggestions': event.suggestions,
      'timestamp': event.timestamp.toIso8601String(),
      if (event.metadata != null) 'metadata': _sanitizeMetadata(event.metadata!),
    };
  }

  /// Performance summary.
  Map<String, dynamic> performance(Map<String, dynamic> params) {
    final perfEvents = engine.eventBus.historyFor('performance');
    return {
      'jank_event_count': perfEvents.length,
      'recent_jank': perfEvents.take(3).map((e) => {
            'title': e.title,
            'severity': e.severity.name,
            'frame_duration_ms': e.metadata?['frame_duration_ms'],
            'consecutive_janks': e.metadata?['consecutive_janks'],
          }).toList(),
      'module_state': engine.modules
          .where((m) => m.id == 'performance')
          .map((m) => m.currentState)
          .firstOrNull ?? {},
    };
  }

  /// Memory summary.
  Map<String, dynamic> memory(Map<String, dynamic> params) {
    final memEvents = engine.eventBus.historyFor('memory');
    return {
      'warning_count': memEvents.length,
      'recent_warnings': memEvents.take(3).map((e) => {
            'title': e.title,
            'severity': e.severity.name,
          }).toList(),
      'module_state': engine.modules
          .where((m) => m.id == 'memory')
          .map((m) => m.currentState)
          .firstOrNull ?? {},
    };
  }

  /// Error summary.
  Map<String, dynamic> errors(Map<String, dynamic> params) {
    final errorEvents = engine.eventBus.historyFor('errors');
    return {
      'error_count': errorEvents.length,
      'recent_errors': errorEvents.take(5).map((e) => {
            'title': sanitizer.sanitizeValue(e.title),
            'severity': e.severity.name,
            'suggestions': e.suggestions.take(2).toList(),
          }).toList(),
    };
  }

  Map<String, dynamic> _sanitizeMetadata(Map<String, dynamic> metadata) {
    return metadata.map((key, value) {
      if (value is String) return MapEntry(key, sanitizer.sanitizeValue(value));
      return MapEntry(key, value);
    });
  }
}
