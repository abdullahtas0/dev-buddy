// packages/dev_buddy/example/lib/pages/network_demo_page.dart
import 'dart:io';
import 'package:flutter/material.dart';

/// Demonstrates network issues that DevBuddy's NetworkModule can detect:
/// - Slow API calls (3 second delay)
/// - 401 Unauthorized errors
/// - 404 Not Found errors
/// - 500 Internal Server errors
class NetworkDemoPage extends StatefulWidget {
  const NetworkDemoPage({super.key});

  @override
  State<NetworkDemoPage> createState() => _NetworkDemoPageState();
}

class _NetworkDemoPageState extends State<NetworkDemoPage> {
  String _status = 'Tap a button to make a network request.';
  bool _loading = false;

  Future<void> _makeRequest({
    required String label,
    required String url,
  }) async {
    setState(() {
      _loading = true;
      _status = 'Requesting: $label...';
    });

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final statusCode = response.statusCode;

      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = '$label completed with status $statusCode';
      });

      client.close();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = '$label failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'This page makes real HTTP requests that trigger '
              'DevBuddy\'s Network module. The module intercepts all '
              'HttpClient traffic via HttpOverrides.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),

          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_status, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Slow request
          _NetworkButton(
            icon: Icons.hourglass_bottom,
            label: 'Slow API Call (3s delay)',
            description: 'Makes a request to httpbin.org with a 3 second delay. '
                'DevBuddy flags requests over 2 seconds as slow.',
            color: Colors.orange,
            onTap: _loading
                ? null
                : () => _makeRequest(
                      label: 'Slow API',
                      url: 'https://httpbin.org/delay/3',
                    ),
          ),

          // 401 error
          _NetworkButton(
            icon: Icons.lock_outline,
            label: '401 Unauthorized',
            description: 'Triggers an authentication error. DevBuddy suggests '
                'checking tokens and refresh logic.',
            color: Colors.red,
            onTap: _loading
                ? null
                : () => _makeRequest(
                      label: '401 Error',
                      url: 'https://httpbin.org/status/401',
                    ),
          ),

          // 404 error
          _NetworkButton(
            icon: Icons.search_off,
            label: '404 Not Found',
            description: 'Requests a non-existent endpoint. DevBuddy flags '
                'the missing resource.',
            color: Colors.amber,
            onTap: _loading
                ? null
                : () => _makeRequest(
                      label: '404 Error',
                      url: 'https://httpbin.org/status/404',
                    ),
          ),

          // 500 error
          _NetworkButton(
            icon: Icons.cloud_off,
            label: '500 Internal Server Error',
            description: 'Simulates a server crash. DevBuddy reports the '
                'server-side failure with suggestions.',
            color: Colors.red.shade700,
            onTap: _loading
                ? null
                : () => _makeRequest(
                      label: '500 Error',
                      url: 'https://httpbin.org/status/500',
                    ),
          ),
        ],
      ),
    );
  }
}

class _NetworkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const _NetworkButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                    const SizedBox(height: 4),
                    Text(description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
