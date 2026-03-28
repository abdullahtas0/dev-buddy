import '../../core/severity.dart';

/// A single accessibility finding from an audit.
class AccessibilityFinding {
  /// Rule identifier (e.g., 'touch-target-size', 'missing-label').
  final String ruleId;

  /// Human-readable rule name.
  final String ruleName;

  final Severity severity;
  final String description;
  final String? suggestion;

  /// Bounding rect of the element (for visual overlay highlighting).
  /// Format: [left, top, width, height] in logical pixels.
  final List<double>? bounds;

  /// Widget type that triggered this finding.
  final String? widgetType;

  const AccessibilityFinding({
    required this.ruleId,
    required this.ruleName,
    required this.severity,
    required this.description,
    this.suggestion,
    this.bounds,
    this.widgetType,
  });

  Map<String, dynamic> toJson() => {
        'rule_id': ruleId,
        'rule_name': ruleName,
        'severity': severity.name,
        'description': description,
        if (suggestion != null) 'suggestion': suggestion,
        if (bounds != null) 'bounds': bounds,
        if (widgetType != null) 'widget_type': widgetType,
      };
}

/// Result of an accessibility audit.
class AccessibilityAuditResult {
  final List<AccessibilityFinding> findings;
  final double score;
  final int totalElements;
  final int passedElements;

  const AccessibilityAuditResult({
    required this.findings,
    required this.score,
    required this.totalElements,
    required this.passedElements,
  });

  int get failedElements => totalElements - passedElements;

  List<AccessibilityFinding> get critical =>
      findings.where((f) => f.severity == Severity.critical).toList();

  List<AccessibilityFinding> get warnings =>
      findings.where((f) => f.severity == Severity.warning).toList();

  Map<String, dynamic> toJson() => {
        'score': score,
        'total_elements': totalElements,
        'passed_elements': passedElements,
        'failed_elements': failedElements,
        'critical_count': critical.length,
        'warning_count': warnings.length,
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}

/// Represents a semantics node extracted from the Flutter widget tree.
///
/// This is a platform-agnostic representation — the Flutter module extracts
/// real SemanticsNode data and feeds it into this pure Dart auditor.
class SemanticElementInfo {
  final String? label;
  final String? hint;
  final String? value;
  final bool isButton;
  final bool isTextField;
  final bool isLink;
  final bool isImage;
  final bool hasAction;
  final double width;
  final double height;
  final double left;
  final double top;
  final String? widgetType;

  const SemanticElementInfo({
    this.label,
    this.hint,
    this.value,
    this.isButton = false,
    this.isTextField = false,
    this.isLink = false,
    this.isImage = false,
    this.hasAction = false,
    this.width = 0,
    this.height = 0,
    this.left = 0,
    this.top = 0,
    this.widgetType,
  });
}

/// Audits semantic elements against WCAG 2.1 guidelines.
///
/// Pure Dart — receives extracted element info and produces findings.
/// The Flutter module handles the actual SemanticsNode tree traversal.
class AccessibilityAuditor {
  /// Minimum touch target size in logical pixels (WCAG 2.5.5 AAA = 44px, we use 48dp).
  final double minTouchTargetSize;

  const AccessibilityAuditor({this.minTouchTargetSize = 48.0});

  /// Audit a list of semantic elements.
  AccessibilityAuditResult audit(List<SemanticElementInfo> elements) {
    final findings = <AccessibilityFinding>[];
    var passedCount = 0;

    for (final element in elements) {
      final elementFindings = _auditElement(element);
      if (elementFindings.isEmpty) {
        passedCount++;
      } else {
        findings.addAll(elementFindings);
      }
    }

    final score = elements.isEmpty
        ? 100.0
        : (passedCount / elements.length * 100).clamp(0.0, 100.0);

    return AccessibilityAuditResult(
      findings: findings,
      score: score,
      totalElements: elements.length,
      passedElements: passedCount,
    );
  }

  List<AccessibilityFinding> _auditElement(SemanticElementInfo element) {
    final findings = <AccessibilityFinding>[];

    // Rule 1: Touch target size (WCAG 2.5.5)
    if (element.hasAction || element.isButton || element.isLink) {
      if (element.width < minTouchTargetSize ||
          element.height < minTouchTargetSize) {
        findings.add(AccessibilityFinding(
          ruleId: 'touch-target-size',
          ruleName: 'Touch Target Too Small',
          severity: element.width < 32 || element.height < 32
              ? Severity.critical
              : Severity.warning,
          description:
              '${element.widgetType ?? 'Element'} is ${element.width.round()}x'
              '${element.height.round()}dp. Minimum: ${minTouchTargetSize.round()}x'
              '${minTouchTargetSize.round()}dp.',
          suggestion: 'Wrap with SizedBox(width: 48, height: 48) or use '
              'MaterialTapTargetSize.padded',
          bounds: [element.left, element.top, element.width, element.height],
          widgetType: element.widgetType,
        ));
      }
    }

    // Rule 2: Missing semantic label (WCAG 1.1.1)
    if ((element.isButton || element.isLink || element.isImage) &&
        (element.label == null || element.label!.isEmpty) &&
        (element.hint == null || element.hint!.isEmpty) &&
        (element.value == null || element.value!.isEmpty)) {
      findings.add(AccessibilityFinding(
        ruleId: 'missing-label',
        ruleName: 'Missing Accessibility Label',
        severity: Severity.critical,
        description:
            '${element.widgetType ?? 'Interactive element'} has no semantic label. '
            'Screen readers cannot describe this element to users.',
        suggestion: 'Add Semantics(label: "descriptive text") or '
            'use tooltip property',
        bounds: [element.left, element.top, element.width, element.height],
        widgetType: element.widgetType,
      ));
    }

    // Rule 3: Image without description (WCAG 1.1.1)
    // Skip if already caught by Rule 2 (missing-label covers interactive images)
    if (element.isImage &&
        !findings.any((f) => f.ruleId == 'missing-label') &&
        (element.label == null || element.label!.isEmpty)) {
      findings.add(AccessibilityFinding(
        ruleId: 'image-no-description',
        ruleName: 'Image Without Description',
        severity: Severity.warning,
        description:
            '${element.widgetType ?? 'Image'} has no alternative text. '
            'Visually impaired users cannot understand this content.',
        suggestion: 'Add semanticLabel to Image widget or wrap with '
            'Semantics(label: "description")',
        bounds: [element.left, element.top, element.width, element.height],
        widgetType: element.widgetType,
      ));
    }

    return findings;
  }
}
