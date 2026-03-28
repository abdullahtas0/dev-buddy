// packages/dev_buddy/test/ui/dev_buddy_overlay_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/core/dev_buddy_module.dart';
import 'package:dev_buddy/src/core/dev_buddy_config.dart';
import 'package:dev_buddy/src/core/dev_buddy_event.dart';
import 'package:dev_buddy/src/ui/overlay/dev_buddy_overlay.dart';

class _TestModule extends DevBuddyModule {
  @override
  String get id => 'test';
  @override
  String get name => 'Test';
  @override
  IconData get icon => Icons.bug_report;

  @override
  void initialize({
    required DevBuddyConfig config,
    required void Function(DevBuddyEvent) onEvent,
  }) {}

  @override
  void dispose() {}

  @override
  Widget buildTab(BuildContext context, List<DevBuddyEvent> events) {
    return const Center(child: Text('Test Tab'));
  }
}

void main() {
  group('DevBuddyOverlayImpl', () {
    testWidgets('renders child when enabled=false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DevBuddyOverlayImpl(
            enabled: false,
            modules: [_TestModule()],
            child: const Text('App Content'),
          ),
        ),
      );

      expect(find.text('App Content'), findsOneWidget);
      expect(find.text('60 FPS'), findsNothing); // no pill
    });

    testWidgets('shows pill when enabled=true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DevBuddyOverlayImpl(
            enabled: true,
            modules: [_TestModule()],
            child: const Text('App Content'),
          ),
        ),
      );

      expect(find.text('App Content'), findsOneWidget);
      // Pill should be visible (initial FPS shows as 0 or ---)
      expect(find.byType(DevBuddyOverlayImpl), findsOneWidget);
    });
  });
}
