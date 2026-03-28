// packages/dev_buddy/lib/src/modules/network/network_analyzer.dart
import '../../core/severity.dart';
import 'network_event.dart';

class NetworkAnalysis {
  final Severity severity;
  final String title;
  final String description;
  final List<String> suggestions;

  const NetworkAnalysis({
    required this.severity,
    required this.title,
    required this.description,
    required this.suggestions,
  });
}

/// Analyzes network request events and produces human-readable diagnostics.
class NetworkAnalyzer {
  final int slowThresholdMs;

  const NetworkAnalyzer({required this.slowThresholdMs});

  NetworkAnalysis analyze(NetworkRequestEvent event) {
    // Check error status codes first
    if (event.statusCode != null && event.statusCode! >= 400) {
      return _analyzeErrorStatus(event);
    }

    // Check for slow requests
    if (event.durationMs > slowThresholdMs) {
      return NetworkAnalysis(
        severity: Severity.warning,
        title: 'Slow Request: ${event.method} ${event.url.path}',
        description:
            '${event.durationMs}ms (threshold: ${slowThresholdMs}ms)',
        suggestions: [
          'This request is slow. Check if the backend endpoint is optimized.',
          'Consider adding pagination if fetching large datasets.',
          'Check your network connection speed.',
        ],
      );
    }

    // Connection error
    if (event.errorMessage != null) {
      return NetworkAnalysis(
        severity: Severity.critical,
        title: 'Connection Error: ${event.method} ${event.url.host}',
        description: event.errorMessage!,
        suggestions: [
          'Check device internet connectivity',
          'Verify the server URL is correct',
          'Check if the server is running',
        ],
      );
    }

    // Large response warning
    if (event.responseSize != null && event.responseSize! > 500 * 1024) {
      return NetworkAnalysis(
        severity: Severity.warning,
        title: 'Large Response: ${event.method} ${event.url.path}',
        description:
            '${(event.responseSize! / 1024).round()}KB response in ${event.durationMs}ms',
        suggestions: [
          'Response is over 500KB. Consider pagination or lazy loading.',
          'Use compute() to parse large JSON off the main thread.',
          'For images, use cacheWidth/cacheHeight to reduce memory.',
        ],
      );
    }

    // Success
    return NetworkAnalysis(
      severity: Severity.info,
      title: '${event.method} ${event.url.path} - ${event.statusCode}',
      description: '${event.durationMs}ms',
      suggestions: [],
    );
  }

  NetworkAnalysis _analyzeErrorStatus(NetworkRequestEvent event) {
    final code = event.statusCode!;
    final path = event.url.path;

    return switch (code) {
      401 => NetworkAnalysis(
          severity: Severity.critical,
          title: '401 Unauthorized: $path',
          description: 'Authentication failed for ${event.method} $path',
          suggestions: [
            'Token may have expired. Try refreshing the auth token.',
            'Check if login credentials are correct.',
            'Verify the Authorization header is being sent.',
          ],
        ),
      403 => NetworkAnalysis(
          severity: Severity.critical,
          title: '403 Forbidden: $path',
          description: 'Access denied for ${event.method} $path',
          suggestions: [
            'Your account may not have permission for this resource.',
            'Check API key permissions and scopes.',
          ],
        ),
      404 => NetworkAnalysis(
          severity: Severity.warning,
          title: '404 Not Found: $path',
          description: '${event.method} $path returned 404',
          suggestions: [
            'Check the URL path for typos.',
            'The resource may have been deleted or moved.',
            'Verify the API version in the URL.',
          ],
        ),
      422 => NetworkAnalysis(
          severity: Severity.warning,
          title: '422 Validation Error: $path',
          description: '${event.method} $path - request body rejected',
          suggestions: [
            'Check the request body matches the API schema.',
            'Required fields may be missing.',
            'Data types may not match (e.g., sending string where int expected).',
          ],
        ),
      429 => NetworkAnalysis(
          severity: Severity.warning,
          title: '429 Rate Limited: $path',
          description: 'Too many requests to $path',
          suggestions: [
            'You are sending requests too frequently.',
            'Add request throttling or debouncing.',
            'Check the Retry-After header for wait time.',
          ],
        ),
      >= 500 => NetworkAnalysis(
          severity: Severity.critical,
          title: '$code Server Error: $path',
          description: 'Server failed for ${event.method} $path',
          suggestions: [
            'This is a backend issue, not a client bug.',
            'Check server logs or contact the backend team.',
            'Implement retry with exponential backoff for resilience.',
          ],
        ),
      _ => NetworkAnalysis(
          severity: Severity.warning,
          title: '$code Error: $path',
          description: '${event.method} $path returned $code',
          suggestions: [
            'Check the API documentation for this status code.',
            'Log the full response body for debugging.',
          ],
        ),
    };
  }
}
