// packages/dev_buddy_mcp/bin/server.dart
//
// MCP Server for DevBuddy — bridges Claude Code with a running Flutter app.
//
// Usage:
//   dart run dev_buddy_mcp          # Connects to localhost:8585
//   dart run dev_buddy_mcp 9090     # Connects to custom port
//
// Protocol: JSON-RPC 2.0 over stdin/stdout (MCP standard)
//
// Architecture:
//   Claude Code ──stdin/stdout──► this server ──HTTP──► Flutter app (:8585)

import 'dart:convert';
import 'dart:io';

const _defaultPort = 8585;
const _serverName = 'dev_buddy_mcp';
const _serverVersion = '0.2.0';

late final int _appPort;
late final HttpClient _http;

void main(List<String> args) {
  _appPort = args.isNotEmpty
      ? int.tryParse(args.first) ?? _defaultPort
      : _defaultPort;
  _http = HttpClient()..connectionTimeout = const Duration(seconds: 5);

  _log('DevBuddy MCP Server starting (app port: $_appPort)');

  // Read JSON-RPC messages from stdin line by line
  stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(_handleLine);
}

void _handleLine(String line) async {
  if (line.trim().isEmpty) return;

  try {
    final request = jsonDecode(line) as Map<String, dynamic>;
    final method = request['method'] as String?;
    final id = request['id'];
    final params = request['params'] as Map<String, dynamic>? ?? {};

    _log('← $method (id: $id)');

    Map<String, dynamic> response;

    switch (method) {
      case 'initialize':
        response = _initialize(id, params);

      case 'initialized':
        // Notification, no response needed
        return;

      case 'tools/list':
        response = _toolsList(id);

      case 'tools/call':
        response = await _toolsCall(id, params);

      case 'ping':
        response = _result(id, {});

      default:
        response = _error(id, -32601, 'Method not found: $method');
    }

    _send(response);
  } catch (e) {
    _log('Error processing line: $e');
    _send(_error(null, -32700, 'Parse error: $e'));
  }
}

// ── MCP Protocol Handlers ───────────────────────────────────────────

Map<String, dynamic> _initialize(dynamic id, Map<String, dynamic> params) {
  return _result(id, {
    'protocolVersion': '2024-11-05',
    'capabilities': {'tools': {}},
    'serverInfo': {'name': _serverName, 'version': _serverVersion},
  });
}

Map<String, dynamic> _toolsList(dynamic id) {
  return _result(id, {
    'tools': [
      _toolDef(
        'dev_buddy/diagnostics',
        'Get current diagnostic snapshot: FPS, memory, severity, top issues from running Flutter app',
        {},
      ),
      _toolDef(
        'dev_buddy/suggest',
        'Get AI-friendly fix suggestions based on active diagnostic issues',
        {},
      ),
      _toolDef(
        'dev_buddy/search_events',
        'Search diagnostic events by module, severity, or text query',
        {
          'query': {'type': 'string', 'description': 'Free text search'},
          'module': {
            'type': 'string',
            'description':
                'Filter: performance, network, errors, memory, rebuilds',
          },
          'severity': {
            'type': 'string',
            'description': 'Minimum: info, warning, critical',
          },
          'limit': {
            'type': 'integer',
            'description': 'Max results (default: 5)',
          },
          'offset': {
            'type': 'integer',
            'description': 'Pagination offset (default: 0)',
          },
        },
      ),
      _toolDef(
        'dev_buddy/search_network',
        'Search captured HTTP requests by URL, status code, or response time',
        {
          'urlPattern': {
            'type': 'string',
            'description': 'URL substring match',
          },
          'statusCode': {
            'type': 'integer',
            'description': 'Filter by status code',
          },
          'minDurationMs': {
            'type': 'integer',
            'description': 'Minimum duration in ms',
          },
          'limit': {
            'type': 'integer',
            'description': 'Max results (default: 5)',
          },
          'offset': {
            'type': 'integer',
            'description': 'Pagination offset (default: 0)',
          },
        },
      ),
      _toolDef(
        'dev_buddy/search_state',
        'Browse state change history for time-travel debugging (Riverpod, BLoC)',
        {
          'source': {
            'type': 'string',
            'description': 'State source (e.g., riverpod:counterProvider)',
          },
          'action': {'type': 'string', 'description': 'Action/event name'},
          'limit': {
            'type': 'integer',
            'description': 'Max results (default: 10)',
          },
          'offset': {
            'type': 'integer',
            'description': 'Pagination offset (default: 0)',
          },
        },
      ),
      _toolDef(
        'dev_buddy/detail',
        'Get full details of a specific diagnostic event by index',
        {
          'index': {
            'type': 'integer',
            'description': 'Event index (0 = newest)',
          },
        },
        required: ['index'],
      ),
      _toolDef(
        'dev_buddy/performance',
        'Get frame timing, FPS, and jank analysis from running Flutter app',
        {},
      ),
      _toolDef(
        'dev_buddy/memory',
        'Get memory usage trend and leak heuristic results',
        {},
      ),
      _toolDef(
        'dev_buddy/errors',
        'Get translated Flutter errors with fix suggestions',
        {},
      ),
    ],
  });
}

Future<Map<String, dynamic>> _toolsCall(
  dynamic id,
  Map<String, dynamic> params,
) async {
  final toolName = params['name'] as String?;
  final toolArgs = (params['arguments'] as Map<String, dynamic>?) ?? {};

  if (toolName == null) {
    return _error(id, -32602, 'Missing tool name');
  }

  try {
    final result = await _callFlutterApp(toolName, toolArgs);
    if (result == null) {
      return _toolResult(id, [
        {
          'type': 'text',
          'text':
              'Flutter app is not running or DevBuddy diagnostic server is not reachable on port $_appPort.\n\nMake sure:\n1. Your Flutter app is running in debug mode\n2. DevBuddyOverlayImpl has enableMcpServer: true\n3. Port $_appPort is not blocked',
        },
      ], isError: true);
    }

    if (result.containsKey('error')) {
      return _toolResult(id, [
        {'type': 'text', 'text': 'Error: ${result['error']}'},
      ], isError: true);
    }

    return _toolResult(id, [
      {
        'type': 'text',
        'text': const JsonEncoder.withIndent('  ').convert(result),
      },
    ]);
  } catch (e) {
    return _toolResult(id, [
      {
        'type': 'text',
        'text':
            'Connection error: $e\n\nIs the Flutter app running with DevBuddy on port $_appPort?',
      },
    ], isError: true);
  }
}

// ── HTTP Bridge to Flutter App ──────────────────────────────────────

Future<Map<String, dynamic>?> _callFlutterApp(
  String toolName,
  Map<String, dynamic> params,
) async {
  try {
    final request = await _http.postUrl(
      Uri.parse('http://localhost:$_appPort/tool'),
    );
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({'tool': toolName, 'params': params}));

    final response = await request.close();
    final body = await utf8.decodeStream(response);

    if (response.statusCode != 200) {
      return {'error': 'HTTP ${response.statusCode}: $body'};
    }

    return jsonDecode(body) as Map<String, dynamic>;
  } on SocketException {
    return null; // App not running
  } on HttpException {
    return null;
  }
}

// ── JSON-RPC Helpers ────────────────────────────────────────────────

Map<String, dynamic> _result(dynamic id, Map<String, dynamic> result) => {
  'jsonrpc': '2.0',
  'id': id,
  'result': result,
};

Map<String, dynamic> _error(dynamic id, int code, String message) => {
  'jsonrpc': '2.0',
  'id': id,
  'error': {'code': code, 'message': message},
};

Map<String, dynamic> _toolResult(
  dynamic id,
  List<Map<String, dynamic>> content, {
  bool isError = false,
}) => _result(id, {'content': content, if (isError) 'isError': true});

Map<String, dynamic> _toolDef(
  String name,
  String description,
  Map<String, dynamic> properties, {
  List<String>? required,
}) => {
  'name': name,
  'description': description,
  'inputSchema': {
    'type': 'object',
    'properties': properties,
    if (required != null) 'required': required,
  },
};

void _send(Map<String, dynamic> message) {
  stdout.writeln(jsonEncode(message));
}

void _log(String message) {
  stderr.writeln('[$_serverName] $message');
}
