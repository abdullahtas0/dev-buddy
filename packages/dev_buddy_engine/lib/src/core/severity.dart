/// Severity levels for diagnostic events.
///
/// Ordered from least to most severe. Use [isAtLeast] for threshold checks.
enum Severity {
  info,
  warning,
  critical;

  /// Returns true if this severity is at least [threshold].
  bool isAtLeast(Severity threshold) => index >= threshold.index;

  /// Human-friendly emoji for display.
  String get emoji => switch (this) {
        Severity.info => 'ℹ️',
        Severity.warning => '🟡',
        Severity.critical => '🔴',
      };

  /// Returns the highest severity from a list of severities.
  static Severity highest(Iterable<Severity> severities) {
    if (severities.isEmpty) return Severity.info;
    return severities.reduce((a, b) => a.index >= b.index ? a : b);
  }
}
