// packages/dev_buddy/test/core/dev_buddy_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/core/dev_buddy_config.dart';
import 'package:dev_buddy/src/core/severity.dart';

void main() {
  group('DevBuddyConfig', () {
    test('default config has sensible values', () {
      const config = DevBuddyConfig();
      expect(config.maxEvents, equals(100));
      expect(config.minSeverity, equals(Severity.info));
      expect(config.enablePerScreenMetrics, isTrue);
      expect(config.locale, isNull); // auto-detect
    });

    test('copyWith overrides specific fields', () {
      const original = DevBuddyConfig();
      final modified = original.copyWith(maxEvents: 50);
      expect(modified.maxEvents, equals(50));
      expect(modified.minSeverity, equals(Severity.info)); // unchanged
    });
  });
}
