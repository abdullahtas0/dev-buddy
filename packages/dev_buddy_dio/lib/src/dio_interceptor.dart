// packages/dev_buddy_dio/lib/src/dio_interceptor.dart
import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:dio/dio.dart';

/// Dio interceptor that captures HTTP request/response data for DevBuddy.
///
/// Feeds [NetworkRequestEvent]s into DevBuddy's event system via a callback,
/// keeping this adapter decoupled from the core controller.
///
/// ## Usage
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(DevBuddyDioInterceptor(
///   onEvent: (event) => networkModule.reportEvent(event),
/// ));
/// ```
class DevBuddyDioInterceptor extends Interceptor {
  /// Callback invoked with each completed request/response cycle.
  final void Function(NetworkRequestEvent event) onEvent;

  /// Maximum characters for body preview. Larger bodies are truncated.
  final int maxBodyPreviewLength;

  /// Whether to capture request/response headers.
  final bool captureHeaders;

  /// Whether to capture request/response body previews.
  final bool captureBody;

  /// Per-instance counter for unique request IDs.
  /// Instance field (not static) so multiple Dio clients get independent IDs.
  int _nextRequestId = 0;

  /// Maps request identity hash → (requestId, startTime).
  /// Uses [identityHashCode] which is stable for the object's lifetime.
  final Map<int, _RequestTracking> _pendingRequests = {};

  /// Entries older than this duration are considered orphaned.
  static const Duration _orphanThreshold = Duration(minutes: 5);

  DevBuddyDioInterceptor({
    required this.onEvent,
    this.maxBodyPreviewLength = 2048,
    this.captureHeaders = false,
    this.captureBody = false,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _cleanupOrphanedRequests();
    _pendingRequests[identityHashCode(options)] = _RequestTracking(
      id: '${_nextRequestId++}',
      startTime: DateTime.now(),
    );
    handler.next(options);
  }

  void _cleanupOrphanedRequests() {
    final now = DateTime.now();
    _pendingRequests.removeWhere(
      (_, tracking) => now.difference(tracking.startTime) > _orphanThreshold,
    );
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _emitEvent(
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
      responseData: response.data,
      responseHeaders: response.headers.map,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _emitEvent(
      requestOptions: err.requestOptions,
      statusCode: err.response?.statusCode,
      responseData: err.response?.data,
      responseHeaders: err.response?.headers.map,
      errorMessage: '${err.type.name}: ${err.message ?? err.type.name}',
    );
    handler.next(err);
  }

  void _emitEvent({
    required RequestOptions requestOptions,
    int? statusCode,
    Object? responseData,
    Map<String, List<String>>? responseHeaders,
    String? errorMessage,
  }) {
    final tracking = _pendingRequests.remove(identityHashCode(requestOptions));
    final now = DateTime.now();
    final startTime = tracking?.startTime;
    final durationMs = startTime != null
        ? now.difference(startTime).inMilliseconds
        : 0;

    final uri = requestOptions.uri;

    // Response size estimation
    int? responseSize;
    String? responseBodyPreview;
    if (responseData != null) {
      final dataStr = responseData.toString();
      responseSize = dataStr.length;
      if (captureBody) {
        responseBodyPreview = dataStr.length > maxBodyPreviewLength
            ? '${dataStr.substring(0, maxBodyPreviewLength)}... [TRUNCATED ${dataStr.length - maxBodyPreviewLength} chars]'
            : dataStr;
      }
    }

    // Request body preview
    String? requestBodyPreview;
    int? requestSize;
    if (captureBody && requestOptions.data != null) {
      final bodyStr = requestOptions.data.toString();
      requestSize = bodyStr.length;
      requestBodyPreview = bodyStr.length > maxBodyPreviewLength
          ? '${bodyStr.substring(0, maxBodyPreviewLength)}... [TRUNCATED ${bodyStr.length - maxBodyPreviewLength} chars]'
          : bodyStr;
    }

    // Headers (flatten Dio's Map<String, List<String>> to Map<String, String>)
    Map<String, String>? reqHeaders;
    Map<String, String>? resHeaders;
    if (captureHeaders) {
      reqHeaders = requestOptions.headers.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
      if (responseHeaders != null) {
        resHeaders = responseHeaders.map((k, v) => MapEntry(k, v.join(', ')));
      }
    }

    // Content-Type extraction
    final contentType = responseHeaders?['content-type']?.firstOrNull;

    onEvent(
      NetworkRequestEvent(
        requestId: tracking?.id ?? '${_nextRequestId++}',
        method: requestOptions.method,
        url: uri,
        statusCode: statusCode,
        durationMs: durationMs,
        requestTimestamp: startTime ?? now,
        responseSize: responseSize,
        requestSize: requestSize,
        errorMessage: errorMessage,
        requestHeaders: reqHeaders,
        responseHeaders: resHeaders,
        requestBody: requestBodyPreview,
        responseBody: responseBodyPreview,
        contentType: contentType,
      ),
    );
  }
}

/// Internal tracking data for a pending request.
class _RequestTracking {
  final String id;
  final DateTime startTime;

  const _RequestTracking({required this.id, required this.startTime});
}
