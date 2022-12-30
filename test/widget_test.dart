// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:inoventory_ui/routes/InoventoryApp.dart';

void main() {
  testWidgets('MyWidget has a title and message', (tester) async {
    // Create the widget by telling the tester to build it.
    const String title = "inoventory";
    await tester.pumpWidget(const InoventoryApp(title: title));

    final titleFinder = find.text(title);

    expect(titleFinder, findsOneWidget);
  });
}
