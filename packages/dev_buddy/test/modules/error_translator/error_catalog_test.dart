// packages/dev_buddy/test/modules/error_translator/error_catalog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/modules/error_translator/error_catalog.dart';

void main() {
  group('ErrorCatalog', () {
    late ErrorCatalog catalog;

    setUp(() {
      catalog = ErrorCatalog.en();
    });

    test('matches RenderFlex overflow', () {
      final result = catalog.translate(
        'A RenderFlex overflowed by 24 pixels on the bottom.',
      );
      expect(result, isNotNull);
      expect(result!.title, contains('Overflow'));
    });

    test('matches setState called after dispose', () {
      final result = catalog.translate(
        "setState() called after dispose(): _MyWidgetState#abc12",
      );
      expect(result, isNotNull);
      expect(result!.suggestions, isNotEmpty);
    });

    test('matches Null check operator on null value', () {
      final result = catalog.translate(
        'Null check operator used on a null value',
      );
      expect(result, isNotNull);
    });

    test('matches type cast error', () {
      final result = catalog.translate(
        "type 'Null' is not a subtype of type 'String'",
      );
      expect(result, isNotNull);
    });

    test('matches RangeError', () {
      final result = catalog.translate(
        'RangeError (index): Invalid value: Valid value range is empty: 0',
      );
      expect(result, isNotNull);
    });

    test('returns null for unknown errors', () {
      final result = catalog.translate(
        'Some completely unknown error message xyz123',
      );
      expect(result, isNull);
    });

    test('catalog has at least 20 patterns', () {
      expect(catalog.patternCount, greaterThanOrEqualTo(20));
    });
  });
}
