// packages/dev_buddy/lib/src/modules/error_translator/error_pattern.dart
import '../../core/severity.dart';

/// Result of matching an error against a pattern.
class ErrorMatchResult {
  final Severity severity;
  final String title;
  final String description;
  final List<String> suggestions;

  const ErrorMatchResult({
    required this.severity,
    required this.title,
    required this.description,
    required this.suggestions,
  });
}

/// A single error pattern with regex matching and human-readable output builders.
///
/// Each pattern captures groups from the error message and uses them
/// to generate contextual titles, descriptions, and suggestions.
class ErrorPattern {
  final RegExp pattern;
  final Severity severity;
  final String Function(RegExpMatch match) titleBuilder;
  final String Function(RegExpMatch match) descriptionBuilder;
  final List<String> suggestions;

  const ErrorPattern({
    required this.pattern,
    required this.severity,
    required this.titleBuilder,
    required this.descriptionBuilder,
    required this.suggestions,
  });

  /// Attempts to match the error message. Returns null if no match.
  ErrorMatchResult? tryMatch(String errorMessage) {
    final match = pattern.firstMatch(errorMessage);
    if (match == null) return null;

    return ErrorMatchResult(
      severity: severity,
      title: titleBuilder(match),
      description: descriptionBuilder(match),
      suggestions: suggestions,
    );
  }
}
