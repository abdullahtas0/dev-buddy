/// Sanitizes diagnostic data before sending to external consumers (AI, logs).
///
/// Three tiers:
/// 1. **Header Redaction:** Authorization, Cookie, API keys → [REDACTED]
/// 2. **PII Detection:** Email, credit card, JWT, AWS keys → [TYPE]
/// 3. **Body Truncation:** Large payloads truncated to [maxLength]
class DataSanitizer {
  final SanitizationLevel level;
  final int maxBodyLength;

  const DataSanitizer({
    this.level = SanitizationLevel.moderate,
    this.maxBodyLength = 500,
  });

  /// Headers that are always redacted.
  static const _sensitiveHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'x-auth-token',
    'x-csrf-token',
    'proxy-authorization',
  };

  /// PII detection patterns — ordered from most specific to broadest.
  static final _piiPatterns = [
    // Payment cards
    _PiiPattern(RegExp(r'\b4[0-9]{12}(?:[0-9]{3})?\b'), '[VISA_CARD]'),
    _PiiPattern(RegExp(r'\b5[1-5][0-9]{14}\b'), '[MC_CARD]'),
    _PiiPattern(RegExp(r'\b3[47][0-9]{13}\b'), '[AMEX_CARD]'),
    // Tokens & keys
    _PiiPattern(
      RegExp(r'eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
      '[JWT_TOKEN]',
    ),
    _PiiPattern(RegExp(r'Bearer\s+\S+', caseSensitive: false), '[AUTH_TOKEN]'),
    _PiiPattern(RegExp(r'AKIA[0-9A-Z]{16}'), '[AWS_KEY]'),
    _PiiPattern(RegExp(r'AIza[0-9A-Za-z_-]{35}'), '[GCP_API_KEY]'),
    _PiiPattern(
      RegExp(
        r'(?:sk_live_|sk_test_|pk_live_|rk_live_)\w{20,}',
        caseSensitive: false,
      ),
      '[STRIPE_KEY]',
    ),
    _PiiPattern(RegExp(r'ghp_[A-Za-z0-9]{36}'), '[GITHUB_TOKEN]'),
    // Personal data
    _PiiPattern(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'),
      '[EMAIL]',
    ),
    _PiiPattern(RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), '[SSN]'),
    _PiiPattern(
      RegExp(r'\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'),
      '[PHONE]',
    ),
    // Generic secrets
    _PiiPattern(
      RegExp(
        r'(?:password|secret|api_key|apikey|token)\s*[:=]\s*\S{8,}',
        caseSensitive: false,
      ),
      '[SECRET]',
    ),
  ];

  /// Additional patterns applied only in strict mode.
  static final _strictPatterns = [
    _PiiPattern(RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'), '[IP_ADDR]'),
  ];

  /// Sanitize a map of HTTP headers.
  Map<String, String> sanitizeHeaders(Map<String, String> headers) {
    if (level == SanitizationLevel.none) return headers;
    return headers.map((key, value) {
      if (_sensitiveHeaders.contains(key.toLowerCase())) {
        return MapEntry(key, '[REDACTED]');
      }
      return MapEntry(
        key,
        level == SanitizationLevel.strict ? _scrubPii(value) : value,
      );
    });
  }

  /// Sanitize a body string (truncate first, then PII scrub).
  ///
  /// Truncates before scrubbing to avoid running 14 regex patterns
  /// on arbitrarily large input (e.g., 50KB response bodies).
  String sanitizeBody(String body) {
    if (level == SanitizationLevel.none) return body;

    var result = body;
    final originalLength = body.length;

    // Truncate first — performance guard for large payloads
    if (result.length > maxBodyLength) {
      result =
          '${result.substring(0, maxBodyLength)}... [TRUNCATED ${originalLength - maxBodyLength} chars]';
    }

    // PII scrubbing (runs on truncated content — fast)
    if (level.index >= SanitizationLevel.moderate.index) {
      result = _scrubPii(result);
    }

    return result;
  }

  /// Sanitize a generic string value.
  String sanitizeValue(String value) {
    if (level == SanitizationLevel.none) return value;
    return _scrubPii(value);
  }

  String _scrubPii(String input) {
    var result = input;
    for (final pattern in _piiPatterns) {
      result = result.replaceAll(pattern.regex, pattern.replacement);
    }
    if (level == SanitizationLevel.strict) {
      for (final pattern in _strictPatterns) {
        result = result.replaceAll(pattern.regex, pattern.replacement);
      }
    }
    return result;
  }
}

/// Sanitization aggressiveness level.
enum SanitizationLevel {
  /// No sanitization — development only, full data access.
  none,

  /// Default: header redaction + common PII patterns.
  moderate,

  /// Enterprise: aggressive PII removal, shorter truncation.
  strict,
}

class _PiiPattern {
  final RegExp regex;
  final String replacement;
  const _PiiPattern(this.regex, this.replacement);
}
