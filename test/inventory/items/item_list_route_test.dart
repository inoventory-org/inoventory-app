import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/inventory/items/item_list_route.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  late MockItemService mockItemService;
  late MockProductService mockProductService;
  late InventoryList dummyList;

  setUp(() {
    mockItemService = MockItemService();
    mockProductService = MockProductService();
    setupMockGetIt(
      mockItemService: mockItemService,
      mockProductService: mockProductService,
    );

    dummyList = InventoryList(1, 'Test List');
  });

  testWidgets('ItemListRoute displays items and handles basic interaction', (tester) async {
    final item1 = Item(1, 1, '111', 'Apple', expirationDate: '2025-01-01');
    final item2 = Item(2, 1, '111', 'Apple', expirationDate: '2025-01-02');
    
    final itemWrapper = ItemWrapper(1, '111', 'Apple', null, null, [item1, item2]);

    when(() => mockItemService.allGroupedBy(1, any())).thenAnswer((_) async => {});
    when(() => mockItemService.all(1)).thenAnswer((_) async => [itemWrapper]);

    await tester.pumpWidget(TestWrapper(
      child: ItemListRoute(list: dummyList),
    ));

    // Wait for the future to resolve
    await tester.pumpAndSettle();

    // Verify item is displayed
    expect(find.text('Apple'), findsOneWidget);
    
    // There are 2 quantity of Apple
    expect(find.text('Quantity: 2'), findsOneWidget);
  });
}
