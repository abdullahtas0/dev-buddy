// packages/dev_buddy_http/lib/src/http_client_wrapper.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:http/http.dart' as http;

/// HTTP client wrapper that captures request/response data for DevBuddy.
///
/// Wraps an [http.Client] and intercepts [send] to measure timing,
/// capture status codes, and report events via a callback.
///
/// **Streaming safety:** Responses larger than [maxCaptureBytes] are
/// passed through without buffering. Only the headers, status code,
/// and timing are captured in that case — the body is NOT read into
/// memory. This prevents memory issues with large file downloads.
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

  /// Maximum response size (bytes) to buffer for inspection.
  ///
  /// Responses with `content-length` exceeding this value are passed
  /// through as a stream without buffering, preventing memory issues
  /// with large downloads. Default: 10 MB.
  final int maxCaptureBytes;

  /// Whether to capture request/response headers.
  final bool captureHeaders;

  /// Whether to capture request/response body previews.
  final bool captureBody;

  DevBuddyHttpClient({
    required http.Client inner,
    required this.onEvent,
    this.maxBodyPreviewLength = 2048,
    this.maxCaptureBytes = 10 * 1024 * 1024,
    this.captureHeaders = false,
    this.captureBody = false,
  }) : _inner = inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();

    try {
      final response = await _inner.send(request);

      // If the response is too large, pass through without buffering.
      final contentLength = response.contentLength;
      if (contentLength != null && contentLength > maxCaptureBytes) {
        return _passThrough(request, response, startTime);
      }

      return _captureAndForward(request, response, startTime);
    } catch (e) {
      final durationMs = DateTime.now().difference(startTime).inMilliseconds;

      onEvent(
        NetworkRequestEvent(
          method: request.method,
          url: request.url,
          durationMs: durationMs,
          requestTimestamp: startTime,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  /// Passes the response stream through without buffering.
  ///
  /// Emits a diagnostic event with headers and timing only — no body
  /// data is captured, keeping memory usage constant regardless of
  /// response size.
  http.StreamedResponse _passThrough(
    http.BaseRequest request,
    http.StreamedResponse response,
    DateTime startTime,
  ) {
    // Emit timing-only event immediately
    onEvent(
      NetworkRequestEvent(
        method: request.method,
        url: request.url,
        statusCode: response.statusCode,
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        requestTimestamp: startTime,
        responseSize: response.contentLength,
        requestHeaders: captureHeaders ? request.headers : null,
        responseHeaders: captureHeaders ? response.headers : null,
        contentType: response.headers['content-type'],
      ),
    );

    // Return the original response untouched
    return response;
  }

  /// Buffers the response to capture body preview and exact size.
  Future<http.StreamedResponse> _captureAndForward(
    http.BaseRequest request,
    http.StreamedResponse response,
    DateTime startTime,
  ) async {
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

    onEvent(
      NetworkRequestEvent(
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
      ),
    );

    // Re-wrap the bytes into a new StreamedResponse for the caller.
    return http.StreamedResponse(
      Stream.value(Uint8List.fromList(bytes)),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      reasonPhrase: response.reasonPhrase,
      persistentConnection: response.persistentConnection,
    );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
