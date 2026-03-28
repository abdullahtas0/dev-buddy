import 'package:dev_buddy_engine/dev_buddy_engine.dart';
import 'package:test/test.dart';

void main() {
  group('AccessibilityAuditor', () {
    const auditor = AccessibilityAuditor();

    test('empty elements list returns 100 score', () {
      final result = auditor.audit([]);
      expect(result.score, 100.0);
      expect(result.findings, isEmpty);
    });

    test('detects small touch target (warning)', () {
      final result = auditor.audit([
        const SemanticElementInfo(
          isButton: true,
          hasAction: true,
          width: 40,
          height: 40,
          widgetType: 'IconButton',
          label: 'Back', // has label, so only touch-target fires
        ),
      ]);

      expect(result.findings, hasLength(1));
      expect(result.findings.first.ruleId, 'touch-target-size');
      expect(result.findings.first.severity, Severity.warning);
    });

    test('detects very small touch target (critical)', () {
      final result = auditor.audit([
        const SemanticElementInfo(
          isButton: true,
          hasAction: true,
          width: 24,
          height: 24,
          widgetType: 'GestureDetector',
        ),
      ]);

      expect(result.findings.first.severity, Severity.critical);
    });

    test('passes adequate touch target with label', () {
      final result = auditor.audit([
        const SemanticElementInfo(
          isButton: true,
          hasAction: true,
          width: 48,
          height: 48,
          widgetType: 'ElevatedButton',
          label: 'Submit',
        ),
      ]);

      expect(result.findings, isEmpty);
      expect(result.passedElements, 1);
    });

    test('detects missing label on button', () {
      final result = auditor.audit([
        const SemanticElementInfo(
          isButton: true,
          hasAction: true,
          width: 48,
          height: 48,
          // No label, hint, or value
        ),
      ]);

      expect(result.findings, hasLength(1));
      expect(result.findings.first.ruleId, 'missing-label');
      expect(result.findings.first.severity, Severity.critical);
    });

    test('passes button with label', () {
      final result = auditor.audit([
        const SemanticElementInfo(
          isButton: true,
          hasAction: true,
          width: 48,
          height: 48,
          label: 'Submit',
        ),
      ]);

      expect(result.findings, isEmpty);
    });

    test('detects image without description (caught by missing-label)', () {
      final result = auditor.audit([
        const SemanticElementInfo(
          isImage: true,
          width: 200,
          height: 200,
          // No label — Rule 2 (missing-label) catches this
        ),
      ]);

      final ruleIds = result.findings.map((f) => f.ruleId).toSet();
      expect(ruleIds, contains('missing-label'));
      // Rule 3 (image-no-description) is suppressed since Rule 2 already fired
      expect(ruleIds, isNot(contains('image-no-description')));
    });

    test('calculates score correctly', () {
      final result = auditor.audit([
        const SemanticElementInfo(isButton: true, hasAction: true, width: 48, height: 48, label: 'OK'), // pass
        const SemanticElementInfo(isButton: true, hasAction: true, width: 20, height: 20), // fail (2 findings)
        const SemanticElementInfo(isButton: true, hasAction: true, width: 48, height: 48, label: 'Cancel'), // pass
      ]);

      expect(result.totalElements, 3);
      expect(result.passedElements, 2);
      expect(result.score, closeTo(66.7, 1.0));
    });

    test('findings include bounds for overlay rendering', () {
      final result = auditor.audit([
        const SemanticElementInfo(
          isButton: true,
          hasAction: true,
          width: 30,
          height: 30,
          left: 100,
          top: 200,
        ),
      ]);

      expect(result.findings.first.bounds, [100, 200, 30, 30]);
    });

    test('toJson serializes correctly', () {
      final result = auditor.audit([
        const SemanticElementInfo(isButton: true, hasAction: true, width: 48, height: 48, label: 'OK'),
      ]);

      final json = result.toJson();
      expect(json['score'], 100.0);
      expect(json['total_elements'], 1);
      expect(json['findings'], isEmpty);
    });

    test('custom minTouchTargetSize', () {
      const strict = AccessibilityAuditor(minTouchTargetSize: 56);
      final result = strict.audit([
        const SemanticElementInfo(
          isButton: true,
          hasAction: true,
          width: 48,
          height: 48,
          label: 'OK',
        ),
      ]);

      // 48 < 56, so it fails with strict auditor
      expect(result.findings, hasLength(1));
      expect(result.findings.first.ruleId, 'touch-target-size');
    });
  });
}
