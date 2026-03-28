/// Immutable record of a single HTTP request/response cycle.
///
/// Core fields (method, url, statusCode, durationMs) are always populated.
/// Enriched fields (headers, body, timeline) are optional and controlled
/// by [DevBuddyConfig] privacy settings.
class NetworkRequestEvent {
  /// A unique identifier for correlating request start/end.
  final String? requestId;

  final String method;
  final Uri url;
  final int? statusCode;
  final int durationMs;
  final DateTime requestTimestamp;
  final int? responseSize;
  final int? requestSize;
  final String? errorMessage;

  // Enriched fields (Phase 3)

  /// Request headers. Populated when config.captureNetworkHeaders is true.
  final Map<String, String>? requestHeaders;

  /// Response headers. Populated when config.captureNetworkHeaders is true.
  final Map<String, String>? responseHeaders;

  /// Request body preview. Truncated to config.maxBodyPreviewSize.
  /// Populated only when config.captureNetworkBody is true.
  final String? requestBody;

  /// Response body preview. Truncated to config.maxBodyPreviewSize.
  /// Populated only when config.captureNetworkBody is true.
  final String? responseBody;

  /// Content-Type from response headers (extracted for convenience).
  final String? contentType;

  /// Detailed timing breakdown (if available from the HTTP client).
  final NetworkTimeline? timeline;

  const NetworkRequestEvent({
    this.requestId,
    required this.method,
    required this.url,
    required this.durationMs,
    required this.requestTimestamp,
    this.statusCode,
    this.responseSize,
    this.requestSize,
    this.errorMessage,
    this.requestHeaders,
    this.responseHeaders,
    this.requestBody,
    this.responseBody,
    this.contentType,
    this.timeline,
  });

  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;
  bool get isError => statusCode != null && statusCode! >= 400;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isRedirect =>
      statusCode != null && statusCode! >= 300 && statusCode! < 400;

  /// Whether this event has enriched data (headers/body).
  bool get hasEnrichedData =>
      requestHeaders != null ||
      responseHeaders != null ||
      requestBody != null ||
      responseBody != null;

  Map<String, dynamic> toJson() => {
        if (requestId != null) 'request_id': requestId,
        'method': method,
        'url': url.toString(),
        'status_code': statusCode,
        'duration_ms': durationMs,
        'timestamp': requestTimestamp.toIso8601String(),
        if (responseSize != null) 'response_size': responseSize,
        if (requestSize != null) 'request_size': requestSize,
        if (errorMessage != null) 'error': errorMessage,
        if (contentType != null) 'content_type': contentType,
        if (requestHeaders != null) 'request_headers': requestHeaders,
        if (responseHeaders != null) 'response_headers': responseHeaders,
        if (requestBody != null) 'request_body': requestBody,
        if (responseBody != null) 'response_body': responseBody,
        if (timeline != null) 'timeline': timeline!.toJson(),
      };
}

/// Detailed timing breakdown for a network request.
///
/// Not all HTTP clients provide this level of detail.
/// Fields are null when the client doesn't support them.
class NetworkTimeline {
  /// DNS resolution time in milliseconds.
  final int? dnsMs;

  /// TCP connection time in milliseconds.
  final int? connectMs;

  /// TLS handshake time in milliseconds.
  final int? tlsMs;

  /// Time to first byte in milliseconds.
  final int? firstByteMs;

  /// Download time in milliseconds.
  final int? downloadMs;

  const NetworkTimeline({
    this.dnsMs,
    this.connectMs,
    this.tlsMs,
    this.firstByteMs,
    this.downloadMs,
  });

  Map<String, dynamic> toJson() => {
        if (dnsMs != null) 'dns_ms': dnsMs,
        if (connectMs != null) 'connect_ms': connectMs,
        if (tlsMs != null) 'tls_ms': tlsMs,
        if (firstByteMs != null) 'first_byte_ms': firstByteMs,
        if (downloadMs != null) 'download_ms': downloadMs,
      };
}
