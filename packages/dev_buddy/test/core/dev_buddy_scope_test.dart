// packages/dev_buddy/test/core/dev_buddy_scope_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/core/dev_buddy_scope.dart';
import 'package:dev_buddy/src/core/dev_buddy_controller.dart';
import 'package:dev_buddy/src/core/dev_buddy_config.dart';

void main() {
  group('DevBuddyScope', () {
    testWidgets('provides controller to descendants', (tester) async {
      final controller = DevBuddyController(
        modules: [],
        config: const DevBuddyConfig(),
      );

      late DevBuddyController found;

      await tester.pumpWidget(
        DevBuddyScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              found = DevBuddyScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(identical(found, controller), isTrue);
    });

    testWidgets('maybeOf returns null when no scope in tree', (tester) async {
      DevBuddyController? found;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            found = DevBuddyScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );

      expect(found, isNull);
    });
  });
}
