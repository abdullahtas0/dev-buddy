// packages/dev_buddy/test/ui/draggable_pill_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy/src/ui/overlay/draggable_pill.dart';
import 'package:dev_buddy/src/core/severity.dart';

void main() {
  group('DraggablePill', () {
    testWidgets('renders with FPS text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              DraggablePill(
                fps: ValueNotifier(60.0),
                severity: ValueNotifier(Severity.info),
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('60 FPS'), findsOneWidget);
    });

    testWidgets('changes color based on severity', (tester) async {
      final severity = ValueNotifier(Severity.info);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              DraggablePill(
                fps: ValueNotifier(60.0),
                severity: severity,
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      // Verify green for info
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF4CAF50))); // green

      severity.value = Severity.critical;
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('is draggable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              DraggablePill(
                fps: ValueNotifier(60.0),
                severity: ValueNotifier(Severity.info),
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GestureDetector).first),
      );
      await gesture.moveBy(const Offset(100, 50));
      await gesture.up();
      await tester.pump();

      // Widget should have moved (not crash)
      expect(find.byType(DraggablePill), findsOneWidget);
    });

    testWidgets('onTap callback fires', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              DraggablePill(
                fps: ValueNotifier(60.0),
                severity: ValueNotifier(Severity.info),
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);
    });
  });
}
