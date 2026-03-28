import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_buddy_example/main.dart';

void main() {
  testWidgets('ShopBuddy renders with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const DevBuddyExampleApp());
    await tester.pumpAndSettle();

    // Bottom nav should have 3 tabs
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Inspector'), findsOneWidget);

    // Shop tab should show ShopBuddy title
    expect(find.text('ShopBuddy'), findsOneWidget);
  });

  testWidgets('Can navigate to Cart tab', (WidgetTester tester) async {
    await tester.pumpWidget(const DevBuddyExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('Can navigate to Inspector tab', (WidgetTester tester) async {
    await tester.pumpWidget(const DevBuddyExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inspector'));
    await tester.pumpAndSettle();

    expect(find.text('DevBuddy Inspector'), findsOneWidget);
    expect(find.byIcon(Icons.camera), findsOneWidget);
  });
}
