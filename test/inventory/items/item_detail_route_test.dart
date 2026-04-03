import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/inventory/items/routes/item_detail_route.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  late MockItemService mockItemService;
  late MockProductService mockProductService;
  late InventoryList dummyList;
  late ItemWrapper dummyWrapper;

  setUp(() {
    mockItemService = MockItemService();
    mockProductService = MockProductService();
    setupMockGetIt(
      mockItemService: mockItemService,
      mockProductService: mockProductService,
    );
    
    // Register fallback value for mocktail matching
    registerFallbackValue(Item(0, 0, '', ''));

    dummyList = InventoryList(1, 'Test List');
    
    final item1 = Item(1, 1, '111', 'Apple', expirationDate: '2025-01-01');
    final item2 = Item(2, 1, '111', 'Apple', expirationDate: '2026-06-06');
    dummyWrapper = ItemWrapper(1, '111', 'Apple', null, null, [item1, item2]);
  });

  testWidgets('ItemDetailRoute displays product info and instances', (tester) async {
    await tester.pumpWidget(TestWrapper(
      child: ItemDetailRoute(itemWrapper: dummyWrapper, list: dummyList),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget); // Column display name
    expect(find.text('EAN: 111'), findsOneWidget);
    expect(find.text('Inventory Items (2)'), findsOneWidget);
    expect(find.text('Expires: 2025-01-01'), findsOneWidget);
    expect(find.text('Expires: 2026-06-06'), findsOneWidget);
  });

  testWidgets('ItemDetailRoute calls delete when delete is pressed', (tester) async {
    when(() => mockItemService.delete(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(TestWrapper(
      child: ItemDetailRoute(itemWrapper: dummyWrapper, list: dummyList),
    ));
    await tester.pumpAndSettle();

    // Tap the first delete button
    Finder deleteButtons = find.byIcon(Icons.delete_outline);
    expect(deleteButtons, findsNWidgets(2));
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    verify(() => mockItemService.delete(1, 1)).called(1);
    expect(find.text('Item deleted'), findsOneWidget);
    
    // The list length should now be 1
    expect(find.text('Inventory Items (1)'), findsOneWidget);
    expect(find.text('Expires: 2025-01-01'), findsNothing);
  });
  
  testWidgets('ItemDetailRoute automatically pops when last item is deleted', (tester) async {
    when(() => mockItemService.delete(any(), any())).thenAnswer((_) async {});
    
    // Pass wrapper with 1 item
    final item1 = Item(1, 1, '111', 'Apple', expirationDate: '2025-01-01');
    final singleItemWrapper = ItemWrapper(1, '111', 'Apple', null, null, [item1]);

    await tester.pumpWidget(TestWrapper(
      child: ItemDetailRoute(itemWrapper: singleItemWrapper, list: dummyList),
    ));
    await tester.pumpAndSettle();

    // Tap delete
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    verify(() => mockItemService.delete(1, 1)).called(1);
    // Should have popped, finding specific text from route should be Nothing
    expect(find.text('EAN: 111'), findsNothing);
  });

  testWidgets('ItemDetailRoute calls _viewProductDetails and navigates', (tester) async {
    final mockProduct = Product('1', 'Apple', ean: '111');
    when(() => mockProductService.search(any())).thenAnswer((_) async => [mockProduct]);

    await tester.pumpWidget(TestWrapper(
      child: ItemDetailRoute(itemWrapper: dummyWrapper, list: dummyList),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Product Details'));
    await tester.pumpAndSettle();

    verify(() => mockProductService.search('111')).called(1);
  });
}
