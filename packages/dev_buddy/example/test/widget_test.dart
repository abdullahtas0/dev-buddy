import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy_example/main.dart';

void main() {
  testWidgets('Example app renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const DevBuddyExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('DevBuddy Demos'), findsOneWidget);
    expect(find.text('Jank Demo'), findsOneWidget);
    expect(find.text('Engine Snapshot'), findsOneWidget);
  });
}
