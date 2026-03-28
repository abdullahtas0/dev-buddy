// packages/dev_buddy/test/modules/error_translator/error_pattern_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/modules/error_translator/error_pattern.dart';
import 'package:dev_buddy/src/core/severity.dart';

void main() {
  group('ErrorPattern', () {
    test('matches RenderFlex overflow error and extracts pixels', () {
      final pattern = ErrorPattern(
        pattern: RegExp(r'RenderFlex overflowed by ([\d.]+) pixels on the (\w+)'),
        severity: Severity.critical,
        titleBuilder: (match) => 'Overflow: ${match[1]}px ${match[2]}',
        descriptionBuilder: (match) =>
            'Content overflows by ${match[1]} pixels on the ${match[2]} side.',
        suggestions: [
          'Wrap the overflowing widget with Expanded or Flexible',
          'Add SingleChildScrollView as a parent',
          'Check if a fixed-size Container is constraining the content',
        ],
      );

      final match = pattern.tryMatch(
        'A RenderFlex overflowed by 24.5 pixels on the bottom.',
      );

      expect(match, isNotNull);
      expect(match!.title, equals('Overflow: 24.5px bottom'));
      expect(match.severity, equals(Severity.critical));
      expect(match.suggestions, hasLength(3));
    });

    test('returns null for non-matching error', () {
      final pattern = ErrorPattern(
        pattern: RegExp(r'RenderFlex overflowed'),
        severity: Severity.critical,
        titleBuilder: (_) => 'Overflow',
        descriptionBuilder: (_) => 'desc',
        suggestions: [],
      );

      final match = pattern.tryMatch('Completely different error');
      expect(match, isNull);
    });
  });
}
