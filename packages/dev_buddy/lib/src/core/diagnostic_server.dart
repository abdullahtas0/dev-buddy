// packages/dev_buddy/lib/src/core/diagnostic_server.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:flutter/foundation.dart';

/// Debug-only HTTP server that exposes [DevBuddyEngine] data on localhost.
///
/// This server enables the MCP bridge: Claude Code's MCP server process
/// queries this HTTP endpoint to read diagnostic data from the running app.
///
/// **Only runs in debug mode.** In release builds, [start] is a no-op.
///
/// ## Architecture
/// ```
/// Flutter App (this server)  ──HTTP──►  MCP Server  ──stdin/stdout──►  Claude Code
///        :8585                         (bin/server.dart)
/// ```
///
/// ## Endpoints
/// - `GET /health` — Server health check
/// - `GET /snapshot` — Full engine snapshot
/// - `GET /events?module=X&limit=N` — Quick event query
/// - `POST /tool` — Execute any MCP tool (body: `{"tool":"...","params":{}}`)
class DevBuddyDiagnosticServer {
  final DevBuddyEngine engine;
  final int port;
  HttpServer? _server;
  late final DataSanitizer _sanitizer;

  DevBuddyDiagnosticServer({
    required this.engine,
    this.port = 8585,
    DataSanitizer? sanitizer,
  }) {
    _sanitizer = sanitizer ?? const DataSanitizer();
  }

  /// Whether the server is currently running.
  bool get isRunning => _server != null;

  /// Start the diagnostic server. No-op in release mode.
  Future<void> start() async {
    if (!kDebugMode) return;
    if (_server != null) return;

    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        port,
        shared: true,
      );

      debugPrint(
        '🔧 DevBuddy diagnostic server running on http://localhost:$port',
      );

      _server!.listen(
        _handleRequest,
        onError: (e) {
          debugPrint('DevBuddy server error: $e');
        },
      );
    } catch (e) {
      debugPrint('DevBuddy server failed to start on port $port: $e');
    }
  }

  /// Stop the server and release the port.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type')
      ..set('Content-Type', 'application/json');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      return;
    }

    try {
      switch (request.uri.path) {
        case '/health':
          await _json(request, {'status': 'ok', 'engine': 'running'});

        case '/snapshot':
          await _json(request, engine.snapshot());

        case '/events':
          await _handleEvents(request);

        case '/tool':
          await _handleTool(request);

        case '/tools':
          await _json(request, {'tools': _toolNames});

        default:
          request.response.statusCode = 404;
          await _json(request, {'error': 'Not found: ${request.uri.path}'});
      }
    } catch (e) {
      request.response.statusCode = 500;
      await _json(request, {'error': e.toString()});
    }
  }

  // ── Tool dispatch ─────────────────────────────────────────────────

  static const _toolNames = [
    'dev_buddy/diagnostics',
    'dev_buddy/suggest',
    'dev_buddy/search_events',
    'dev_buddy/search_network',
    'dev_buddy/search_state',
    'dev_buddy/detail',
    'dev_buddy/performance',
    'dev_buddy/memory',
    'dev_buddy/errors',
  ];

  /// Maximum request body size (64 KB). Prevents OOM from oversized POST.
  static const _maxBodyBytes = 64 * 1024;

  Future<void> _handleTool(HttpRequest request) async {
    if (request.method != 'POST') {
      request.response.statusCode = 405;
      await _json(request, {'error': 'POST required'});
      return;
    }

    // Read body with size limit
    final bytes = <int>[];
    await for (final chunk in request) {
      bytes.addAll(chunk);
      if (bytes.length > _maxBodyBytes) {
        request.response.statusCode = 413;
        await _json(request, {'error': 'Request body too large'});
        return;
      }
    }
    final body = utf8.decode(bytes);

    // Parse JSON safely
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      request.response.statusCode = 400;
      await _json(request, {'error': 'Invalid JSON body'});
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      request.response.statusCode = 400;
      await _json(request, {'error': 'Expected JSON object'});
      return;
    }

    final tool = decoded['tool'] as String?;
    final params = (decoded['params'] as Map<String, dynamic>?) ?? {};

    if (tool == null) {
      request.response.statusCode = 400;
      await _json(request, {'error': 'Missing "tool" field'});
      return;
    }

    final result = _dispatchTool(tool, params);
    if (result == null) {
      request.response.statusCode = 404;
      await _json(request, {'error': 'Unknown tool: $tool'});
      return;
    }

    await _json(request, result);
  }

  Map<String, dynamic>? _dispatchTool(
    String tool,
    Map<String, dynamic> params,
  ) {
    switch (tool) {
      case 'dev_buddy/diagnostics':
        return _diagnostics();
      case 'dev_buddy/suggest':
        return _suggest();
      case 'dev_buddy/search_events':
        return _searchEvents(params);
      case 'dev_buddy/search_network':
        return _searchNetwork(params);
      case 'dev_buddy/search_state':
        return _searchState(params);
      case 'dev_buddy/detail':
        return _detail(params);
      case 'dev_buddy/performance':
        return _performance();
      case 'dev_buddy/memory':
        return _memory();
      case 'dev_buddy/errors':
        return _errors();
      default:
        return null;
    }
  }

  // ── Tool implementations (mirror McpTools) ────────────────────────

  Map<String, dynamic> _diagnostics() {
    final snap = engine.snapshot();
    return {
      'overall_severity': snap['overall_severity'],
      'event_count': snap['event_count'],
      'top_issues': engine.eventBus.history
          .take(3)
          .map(
            (e) => {
              'module': e.module,
              'severity': e.severity.name,
              'title': _sanitizer.sanitizeValue(e.title),
            },
          )
          .toList(),
      'state_store': snap['state_store'],
    };
  }

  Map<String, dynamic> _suggest() {
    final events = engine.eventBus.history.take(10);
    return {
      'suggestions': events
          .where((e) => e.suggestions.isNotEmpty)
          .take(5)
          .map(
            (e) => {
              'issue': _sanitizer.sanitizeValue(e.title),
              'severity': e.severity.name,
              'fix': e.suggestions.first,
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> _searchEvents(Map<String, dynamic> params) {
    final query = params['query'] as String?;
    final module = params['module'] as String?;
    final severityStr = params['severity'] as String?;
    final limit = (params['limit'] as int?) ?? 5;
    final offset = (params['offset'] as int?) ?? 0;

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
          .where(
            (e) =>
                e.title.toLowerCase().contains(q) ||
                e.description.toLowerCase().contains(q),
          )
          .toList();
    }

    return {
      'total': results.length,
      'offset': offset,
      'limit': limit,
      'results': results
          .skip(offset)
          .take(limit)
          .map(
            (e) => {
              'module': e.module,
              'severity': e.severity.name,
              'title': _sanitizer.sanitizeValue(e.title),
              'description': _sanitizer.sanitizeBody(e.description),
              'timestamp': e.timestamp.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> _searchNetwork(Map<String, dynamic> params) {
    final urlPattern = params['urlPattern'] as String?;
    final statusCode = params['statusCode'] as int?;
    final minDurationMs = params['minDurationMs'] as int?;
    final limit = (params['limit'] as int?) ?? 5;
    final offset = (params['offset'] as int?) ?? 0;

    var results = engine.eventBus.historyFor('network');
    if (urlPattern != null) {
      results = results
          .where(
            (e) => (e.metadata?['url'] ?? '').toString().contains(urlPattern),
          )
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
      'offset': offset,
      'limit': limit,
      'results': results
          .skip(offset)
          .take(limit)
          .map(
            (e) => {
              'url': _sanitizer.sanitizeValue(
                e.metadata?['url']?.toString() ?? '',
              ),
              'status_code': e.metadata?['status_code'],
              'duration_ms': e.metadata?['duration_ms'],
              'title': _sanitizer.sanitizeValue(e.title),
              'severity': e.severity.name,
              'timestamp': e.timestamp.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> _searchState(Map<String, dynamic> params) {
    final source = params['source'] as String?;
    final action = params['action'] as String?;
    final limit = (params['limit'] as int?) ?? 10;
    final offset = (params['offset'] as int?) ?? 0;

    var results = engine.stateStore.history;
    if (source != null) {
      results = results.where((s) => s.source.contains(source)).toList();
    }
    if (action != null) {
      results = results.where((s) => s.action == action).toList();
    }

    return {
      'total': results.length,
      'offset': offset,
      'limit': limit,
      'results': results
          .skip(offset)
          .take(limit)
          .map(
            (s) => {
              'version': s.version,
              'source': s.source,
              'action': s.action,
              'timestamp': s.timestamp.toIso8601String(),
              'is_anchor': s.isAnchor,
              if (s.serializedDiff != null)
                'diff': _sanitizer.sanitizeBody(s.serializedDiff!),
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> _detail(Map<String, dynamic> params) {
    final index = params['index'] as int? ?? 0;
    final history = engine.eventBus.history;

    if (index < 0 || index >= history.length) {
      return {
        'error': 'Index out of range. History has ${history.length} events.',
      };
    }

    final event = history[index];
    return {
      'module': event.module,
      'severity': event.severity.name,
      'title': _sanitizer.sanitizeValue(event.title),
      'description': _sanitizer.sanitizeBody(event.description),
      'suggestions': event.suggestions,
      'timestamp': event.timestamp.toIso8601String(),
      if (event.metadata != null) 'metadata': event.metadata,
    };
  }

  Map<String, dynamic> _performance() {
    final perfEvents = engine.eventBus.historyFor('performance');
    return {
      'jank_event_count': perfEvents.length,
      'recent_jank': perfEvents
          .take(3)
          .map(
            (e) => {
              'title': e.title,
              'severity': e.severity.name,
              'frame_duration_ms': e.metadata?['frame_duration_ms'],
              'consecutive_janks': e.metadata?['consecutive_janks'],
            },
          )
          .toList(),
      'module_state':
          engine.modules
              .where((m) => m.id == 'performance')
              .map((m) => m.currentState)
              .firstOrNull ??
          {},
    };
  }

  Map<String, dynamic> _memory() {
    final memEvents = engine.eventBus.historyFor('memory');
    return {
      'warning_count': memEvents.length,
      'recent_warnings': memEvents
          .take(3)
          .map((e) => {'title': e.title, 'severity': e.severity.name})
          .toList(),
      'module_state':
          engine.modules
              .where((m) => m.id == 'memory')
              .map((m) => m.currentState)
              .firstOrNull ??
          {},
    };
  }

  Map<String, dynamic> _errors() {
    final errorEvents = engine.eventBus.historyFor('errors');
    return {
      'error_count': errorEvents.length,
      'recent_errors': errorEvents
          .take(5)
          .map(
            (e) => {
              'title': _sanitizer.sanitizeValue(e.title),
              'severity': e.severity.name,
              'suggestions': e.suggestions.take(2).toList(),
            },
          )
          .toList(),
    };
  }

  // ── Events endpoint ───────────────────────────────────────────────

  Future<void> _handleEvents(HttpRequest request) async {
    final module = request.uri.queryParameters['module'];
    final limit =
        int.tryParse(request.uri.queryParameters['limit'] ?? '20') ?? 20;

    var events = engine.eventBus.history;
    if (module != null) {
      events = events.where((e) => e.module == module).toList();
    }

    await _json(request, {
      'total': events.length,
      'events': events.take(limit).map((e) => e.toJson()).toList(),
    });
  }

  Future<void> _json(HttpRequest request, Map<String, dynamic> data) async {
    request.response.write(jsonEncode(data));
    await request.response.close();
  }
}
