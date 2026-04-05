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

  testWidgets('ItemListRoute displays items and handles basic interaction',
      (tester) async {
    final item1 = Item(1, 1, '111', 'Apple', expirationDate: '2025-01-01');
    final item2 = Item(2, 1, '111', 'Apple', expirationDate: '2025-01-02');

    final itemWrapper =
        ItemWrapper(1, '111', 'Apple', null, null, [item1, item2]);

    when(() => mockItemService.allGroupedBy(1, any()))
        .thenAnswer((_) async => {});
    when(() => mockItemService.all(1)).thenAnswer((_) async => [itemWrapper]);

    await tester.pumpWidget(TestWrapper(
      child: ItemListRoute(list: dummyList),
    ));

    // Wait for the future to resolve
    await tester.pumpAndSettle();

    // Verify item is displayed
    expect(find.text('Apple'), findsOneWidget);

    // There are 2 quantity of Apple
    expect(find.text('2'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);
  });

  testWidgets(
      'ItemListRoute deletes random item on swipe when no expiration dates',
      (tester) async {
    final item1 = Item(1, 1, '111', 'Apple');
    final item2 = Item(2, 1, '111', 'Apple');

    final itemWrapper =
        ItemWrapper(1, '111', 'Apple', null, null, [item1, item2]);

    when(() => mockItemService.allGroupedBy(1, any()))
        .thenAnswer((_) async => {});
    when(() => mockItemService.all(1)).thenAnswer((_) async => [itemWrapper]);
    when(() => mockItemService.delete(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(TestWrapper(
      child: ItemListRoute(list: dummyList),
    ));
    await tester.pumpAndSettle();

    // Swipe to dismiss
    await tester.drag(find.text('Apple'), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    // Verify item-choice dialog NOT shown and choose checkout
    expect(find.text('Choose item'), findsNothing);
    await tester.tap(find.text('Check Out'));
    await tester.pumpAndSettle();
    verify(() => mockItemService.delete(1, 1)).called(1);
  });

  testWidgets(
      'ItemListRoute shows dialog on swipe when multiple expiration dates exist',
      (tester) async {
    final item1 = Item(1, 1, '111', 'Apple', expirationDate: '2025-01-01');
    final item2 = Item(2, 1, '111', 'Apple', expirationDate: '2026-06-06');

    final itemWrapper =
        ItemWrapper(1, '111', 'Apple', null, null, [item1, item2]);

    when(() => mockItemService.allGroupedBy(1, any()))
        .thenAnswer((_) async => {});
    when(() => mockItemService.all(1)).thenAnswer((_) async => [itemWrapper]);
    when(() => mockItemService.delete(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(TestWrapper(
      child: ItemListRoute(list: dummyList),
    ));
    await tester.pumpAndSettle();

    // Swipe to dismiss
    await tester.drag(find.text('Apple'), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    // Verify dialog IS shown
    expect(find.text('Choose item'), findsOneWidget);

    // Tap the specific expiration date to delete
    await tester.tap(find.text('2026-06-06'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check Out'));
    await tester.pumpAndSettle();

    // Verify delete called for item2 (which has ID 2)
    verify(() => mockItemService.delete(1, 2)).called(1);
  });

  testWidgets('ItemListRoute opens item when user chooses open action',
      (tester) async {
    final item1 = Item(1, 1, '111', 'Apple', expirationDate: '2025-01-01');
    final item2 = Item(2, 1, '111', 'Apple', expirationDate: '2025-01-01');
    final itemWrapper =
        ItemWrapper(1, '111', 'Apple', null, null, [item1, item2]);

    when(() => mockItemService.allGroupedBy(1, any()))
        .thenAnswer((_) async => {});
    when(() => mockItemService.all(1)).thenAnswer((_) async => [itemWrapper]);
    when(() => mockItemService.open(any(), any(),
        expirationDate: any(named: 'expirationDate'))).thenAnswer(
      (_) async => Item(1, 99, '111', 'Apple',
          expirationDate: '2025-01-01', openedAt: '2026-04-05'),
    );

    await tester.pumpWidget(TestWrapper(
      child: ItemListRoute(list: dummyList),
    ));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Apple'), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Item'));
    await tester.pumpAndSettle();

    verify(() => mockItemService.open(1, 1, expirationDate: '2025-01-01'))
        .called(1);
  });
}
