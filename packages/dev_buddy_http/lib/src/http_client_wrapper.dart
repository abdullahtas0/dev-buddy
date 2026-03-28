// packages/dev_buddy_http/lib/src/http_client_wrapper.dart
import 'dart:convert';

import 'package:dev_buddy/dev_buddy.dart';
import 'package:http/http.dart' as http;

/// HTTP client wrapper that captures request/response data for DevBuddy.
///
/// Wraps an [http.Client] and intercepts [send] to measure timing,
/// capture status codes, and report events via a callback.
///
/// ## Usage
/// ```dart
/// final client = DevBuddyHttpClient(
///   inner: http.Client(),
///   onEvent: (event) => networkModule.reportEvent(event),
/// );
/// final response = await client.get(Uri.parse('https://api.example.com'));
/// ```
class DevBuddyHttpClient extends http.BaseClient {
  /// The wrapped HTTP client that performs the actual requests.
  final http.Client _inner;

  /// Callback invoked with each completed request/response cycle.
  final void Function(NetworkRequestEvent event) onEvent;

  /// Maximum characters for body preview. Larger bodies are truncated.
  final int maxBodyPreviewLength;

  /// Whether to capture request/response headers.
  final bool captureHeaders;

  /// Whether to capture request/response body previews.
  final bool captureBody;

  DevBuddyHttpClient({
    required http.Client inner,
    required this.onEvent,
    this.maxBodyPreviewLength = 2048,
    this.captureHeaders = false,
    this.captureBody = false,
  }) : _inner = inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();

    try {
      final response = await _inner.send(request);

      // Read the streamed response body so we can measure size
      // and still return a valid StreamedResponse to the caller.
      final bytes = await response.stream.toBytes();
      final durationMs = DateTime.now().difference(startTime).inMilliseconds;

      // Body previews (opt-in)
      String? responseBodyPreview;
      if (captureBody && bytes.isNotEmpty) {
        final bodyStr = utf8.decode(bytes, allowMalformed: true);
        responseBodyPreview = bodyStr.length > maxBodyPreviewLength
            ? '${bodyStr.substring(0, maxBodyPreviewLength)}... [TRUNCATED ${bodyStr.length - maxBodyPreviewLength} chars]'
            : bodyStr;
      }

      String? requestBodyPreview;
      int? requestSize;
      if (captureBody && request is http.Request && request.body.isNotEmpty) {
        requestSize = request.body.length;
        requestBodyPreview = request.body.length > maxBodyPreviewLength
            ? '${request.body.substring(0, maxBodyPreviewLength)}... [TRUNCATED ${request.body.length - maxBodyPreviewLength} chars]'
            : request.body;
      }

      // Content-Type extraction
      final contentType = response.headers['content-type'];

      onEvent(NetworkRequestEvent(
        method: request.method,
        url: request.url,
        statusCode: response.statusCode,
        durationMs: durationMs,
        requestTimestamp: startTime,
        responseSize: bytes.length,
        requestSize: requestSize,
        requestHeaders: captureHeaders ? request.headers : null,
        responseHeaders: captureHeaders ? response.headers : null,
        requestBody: requestBodyPreview,
        responseBody: responseBodyPreview,
        contentType: contentType,
      ));

      // Re-wrap the bytes into a new StreamedResponse for the caller.
      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        reasonPhrase: response.reasonPhrase,
        persistentConnection: response.persistentConnection,
      );
    } catch (e) {
      final durationMs = DateTime.now().difference(startTime).inMilliseconds;

      onEvent(NetworkRequestEvent(
        method: request.method,
        url: request.url,
        durationMs: durationMs,
        requestTimestamp: startTime,
        errorMessage: e.toString(),
      ));

      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
