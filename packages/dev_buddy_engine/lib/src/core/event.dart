import 'severity.dart';

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
  final Map<String, dynamic>? metadata;

  DevBuddyEvent({
    required this.module,
    required this.severity,
    required this.title,
    required this.description,
    required List<String> suggestions,
    DateTime? timestamp,
    this.metadata,
  })  : suggestions = List.unmodifiable(suggestions),
        timestamp = timestamp ?? DateTime.now();

  DevBuddyEvent copyWith({
    String? module,
    Severity? severity,
    String? title,
    String? description,
    List<String>? suggestions,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return DevBuddyEvent(
      module: module ?? this.module,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      suggestions: suggestions ?? List.unmodifiable(this.suggestions),
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
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
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() =>
      'DevBuddyEvent(${severity.emoji} [$module] $title)';
}
