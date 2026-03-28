// packages/dev_buddy/lib/src/modules/network/network_module.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/dev_buddy_config.dart';
import '../../core/dev_buddy_event.dart';
import '../../core/dev_buddy_module.dart';
import '../../core/severity.dart';
import 'network_analyzer.dart';
import 'network_event.dart';
import 'network_interceptor.dart';

/// Monitors all HTTP traffic and flags slow requests, errors, and auth issues.
///
/// Uses [HttpOverrides] to intercept traffic from ANY HTTP client (Dio, http, etc.).
class NetworkModule extends DevBuddyModule {
  @override
  String get id => 'network';
  @override
  String get name => 'Network';
  @override
  IconData get icon => Icons.wifi;

  late NetworkAnalyzer _analyzer;
  late void Function(DevBuddyEvent) _onEvent;
  HttpOverrides? _previousOverrides;
  final List<NetworkRequestEvent> _requests = [];
  static const int _maxRequests = 50;

  @override
  void initialize({
    required DevBuddyConfig config,
    required void Function(DevBuddyEvent event) onEvent,
  }) {
    _analyzer = NetworkAnalyzer(slowThresholdMs: config.slowNetworkThresholdMs);
    _onEvent = onEvent;

    _previousOverrides = HttpOverrides.current;
    HttpOverrides.global = DevBuddyHttpOverrides(
      onEvent: _handleNetworkEvent,
      previous: _previousOverrides,
    );
  }

  @override
  void dispose() {
    HttpOverrides.global = _previousOverrides;
    _requests.clear();
  }

  void _handleNetworkEvent(NetworkRequestEvent request) {
    _requests.insert(0, request);
    if (_requests.length > _maxRequests) {
      _requests.removeRange(_maxRequests, _requests.length);
    }

    final analysis = _analyzer.analyze(request);

    // Only emit events for non-trivial findings
    if (analysis.severity.isAtLeast(Severity.warning)) {
      _onEvent(DevBuddyEvent(
        module: id,
        severity: analysis.severity,
        title: analysis.title,
        description: analysis.description,
        suggestions: analysis.suggestions,
        metadata: request.toJson(),
      ));
    }
  }

  @override
  Widget buildTab(BuildContext context, List<DevBuddyEvent> events) {
    if (_requests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('No network requests captured',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(12),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        return _NetworkRequestTile(request: req);
      },
    );
  }
}

class _NetworkRequestTile extends StatelessWidget {
  final NetworkRequestEvent request;
  const _NetworkRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final color = request.isSuccess
        ? Colors.green
        : request.isError
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${request.statusCode ?? 'ERR'}',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(request.method,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                request.url.path,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${request.durationMs}ms',
              style: TextStyle(
                fontSize: 11,
                color: request.durationMs > 2000 ? Colors.orange : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
