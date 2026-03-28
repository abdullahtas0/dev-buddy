import 'severity.dart';

/// Typed metadata for diagnostic events.
///
/// Each event type has a specific metadata subclass for compile-time
/// safety. Use [CustomMetadata] for plugin/custom events.
sealed class EventMetadata {
  const EventMetadata();

  /// Convert to JSON-serializable map for export.
  Map<String, dynamic> toJson();
}

/// Metadata for performance/jank events.
class PerformanceMetadata extends EventMetadata {
  final double? fps;
  final double? frameDurationMs;
  final int? consecutiveJanks;
  final int? jankCount;

  const PerformanceMetadata({
    this.fps,
    this.frameDurationMs,
    this.consecutiveJanks,
    this.jankCount,
  });

  @override
  Map<String, dynamic> toJson() => {
    if (fps != null) 'fps': fps,
    if (frameDurationMs != null) 'frame_duration_ms': frameDurationMs,
    if (consecutiveJanks != null) 'consecutive_janks': consecutiveJanks,
    if (jankCount != null) 'jank_count': jankCount,
  };
}

/// Metadata for network events.
class NetworkEventMetadata extends EventMetadata {
  final String? url;
  final String? method;
  final int? statusCode;
  final int? durationMs;
  final int? responseSize;
  final String? contentType;
  final String? errorMessage;

  const NetworkEventMetadata({
    this.url,
    this.method,
    this.statusCode,
    this.durationMs,
    this.responseSize,
    this.contentType,
    this.errorMessage,
  });

  @override
  Map<String, dynamic> toJson() => {
    if (url != null) 'url': url,
    if (method != null) 'method': method,
    if (statusCode != null) 'status_code': statusCode,
    if (durationMs != null) 'duration_ms': durationMs,
    if (responseSize != null) 'response_size': responseSize,
    if (contentType != null) 'content_type': contentType,
    if (errorMessage != null) 'error': errorMessage,
  };
}

/// Metadata for rebuild tracking events.
class RebuildMetadata extends EventMetadata {
  final Map<String, int>? rebuilds;
  final List<Map<String, dynamic>>? topRebuilders;
  final int? totalRebuilds;

  const RebuildMetadata({
    this.rebuilds,
    this.topRebuilders,
    this.totalRebuilds,
  });

  @override
  Map<String, dynamic> toJson() => {
    if (rebuilds != null) 'rebuilds': rebuilds,
    if (topRebuilders != null) 'top_rebuilders': topRebuilders,
    if (totalRebuilds != null) 'total_rebuilds': totalRebuilds,
  };
}

/// Metadata for memory events.
class MemoryMetadata extends EventMetadata {
  final int? currentRss;
  final int? peakRss;
  final double? growthRateMbPerMinute;

  const MemoryMetadata({
    this.currentRss,
    this.peakRss,
    this.growthRateMbPerMinute,
  });

  @override
  Map<String, dynamic> toJson() => {
    if (currentRss != null) 'current_rss': currentRss,
    if (peakRss != null) 'peak_rss': peakRss,
    if (growthRateMbPerMinute != null)
      'growth_rate_mb_per_minute': growthRateMbPerMinute,
  };
}

/// Metadata for correlation engine compound events.
class CorrelationMetadata extends EventMetadata {
  final String rule;
  final Map<String, dynamic>? details;

  const CorrelationMetadata({required this.rule, this.details});

  @override
  Map<String, dynamic> toJson() => {
    'rule': rule,
    if (details != null) ...details!,
  };
}

/// Metadata for custom/plugin events — preserves backwards compatibility
/// with the original `Map<String, dynamic>` pattern.
class CustomMetadata extends EventMetadata {
  final Map<String, dynamic> data;

  const CustomMetadata(this.data);

  @override
  Map<String, dynamic> toJson() => data;
}

/// An immutable diagnostic event emitted by a [DiagnosticModule].
///
/// Each event includes a human-readable [title], [description], and
/// actionable [suggestions] the developer can follow to fix the issue.
///
/// All fields are primitives or immutable collections — safe for
/// Isolate transfer via SendPort at O(1) cost.
class DevBuddyEvent {
  final String module;
  final Severity severity;
  final String title;
  final String description;
  final List<String> suggestions;
  final DateTime timestamp;

  /// Typed metadata — use specific subclasses for compile-time safety.
  ///
  /// For backwards compatibility, [metadata] also accepts raw maps via
  /// the constructor, which are wrapped in [CustomMetadata].
  final EventMetadata? typedMetadata;

  /// Legacy accessor for untyped metadata map.
  ///
  /// Returns [typedMetadata.toJson()] for typed metadata, or null.
  Map<String, dynamic>? get metadata => typedMetadata?.toJson();

  DevBuddyEvent({
    required this.module,
    required this.severity,
    required this.title,
    required this.description,
    required List<String> suggestions,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    EventMetadata? typedMetadata,
  }) : suggestions = List.unmodifiable(suggestions),
       timestamp = timestamp ?? DateTime.now(),
       typedMetadata =
           typedMetadata ??
           (metadata != null
               ? CustomMetadata(Map.unmodifiable(metadata))
               : null);

  DevBuddyEvent copyWith({
    String? module,
    Severity? severity,
    String? title,
    String? description,
    List<String>? suggestions,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    EventMetadata? typedMetadata,
  }) {
    return DevBuddyEvent(
      module: module ?? this.module,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      suggestions: suggestions ?? List.unmodifiable(this.suggestions),
      timestamp: timestamp ?? this.timestamp,
      typedMetadata: typedMetadata ?? this.typedMetadata,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module': module,
      'severity': severity.name,
      'title': title,
      'description': description,
      'suggestions': suggestions,
      'timestamp': timestamp.toIso8601String(),
      if (typedMetadata != null) 'metadata': typedMetadata!.toJson(),
    };
  }

  @override
  String toString() => 'DevBuddyEvent(${severity.emoji} [$module] $title)';
}
