// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_overview_route.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('MyWidget has a title and message', (tester) async {
    // Create the widget by telling the tester to build it.
    const String title = "inoventory";
    await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(),
        child: MaterialApp(home: InventoryListRoute(logout: () {
          throw UnimplementedError();
        }))));
    await tester.pump();

    final titleFinder = find.text(title);

    expect(titleFinder, findsOneWidget);
  });
}
