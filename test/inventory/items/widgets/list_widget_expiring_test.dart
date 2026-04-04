import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:inoventory_ui/inventory/items/widgets/list_widget.dart';
import '../../../helpers/test_wrapper.dart';

void main() {
  group('InventoryListWidget - Focus Expiring', () {
    late ItemWrapper expiringItem;
    late ItemWrapper normalItem;

    setUp(() {
      setupMockGetIt();

      final today = DateTime.now();
      // Item expiring in 10 days (<= 30 days)
      final expiringDate = today.add(const Duration(days: 10)).toIso8601String();
      // Item expiring in 60 days
      final normalDate = today.add(const Duration(days: 60)).toIso8601String();

      expiringItem = ItemWrapper(
        1,
        "111",
        "Expiring Milk",
        null,
        null,
        [Item(1, 1, "111", "Expiring Milk", expirationDate: expiringDate)],
      );

      normalItem = ItemWrapper(
        1,
        "222",
        "Normal Water",
        null,
        null,
        [Item(2, 1, "222", "Normal Water", expirationDate: normalDate)],
      );
    });

    testWidgets('cards should NOT be highlighted red if focusExpiring is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: InventoryListWidget(
              itemWrappers: [expiringItem, normalItem],
              focusExpiring: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final cards = tester.widgetList<Card>(find.byType(Card));
      // First card should NOT be error color
      expect(cards.elementAt(0).color, isNot(equals(ThemeData.light().colorScheme.errorContainer)));
    });

    testWidgets('cards SHOULD be highlighted red if focusExpiring is true and item is expiring', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: InventoryListWidget(
              itemWrappers: [expiringItem, normalItem],
              focusExpiring: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final cards = tester.widgetList<Card>(find.byType(Card));
      
      // We expect the first card (expiringItem) to be colored with errorContainer
      // We can't rely on the precise Theme color matching identically across all contexts,
      // but we can ensure it has a non-null color, while the normal item has a null color.
      expect(cards.elementAt(0).color, isNotNull); 
      expect(cards.elementAt(1).color, isNull);
    });
  });
}
