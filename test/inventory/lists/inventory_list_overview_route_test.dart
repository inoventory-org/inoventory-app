import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_overview_route.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  late MockInventoryListService mockListService;
  late MockItemService mockItemService;

  setUp(() {
    mockListService = MockInventoryListService();
    mockItemService = MockItemService();
    setupMockGetIt(
      mockInventoryListService: mockListService,
      mockItemService: mockItemService,
    );
  });

  testWidgets('InventoryListRoute renders lists properly', (tester) async {
    when(() => mockListService.all()).thenAnswer((_) async => [
          InventoryList(1, 'Kitchen'),
          InventoryList(2, 'Open', type: 'OPEN'),
        ]);
    when(() => mockItemService.all(1)).thenAnswer((_) async => []);
    when(() => mockItemService.all(2)).thenAnswer((_) async => []);

    await tester.pumpWidget(TestWrapper(
      child: InventoryListRoute(logout: () async {}),
    ));

    // Initially loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump to resolve future
    await tester.pumpAndSettle();

    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Opened items'), findsOneWidget);
    expect(find.text('0 items'), findsNWidgets(2));
    expect(find.byIcon(Icons.lock_open), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('InventoryListRoute persists reordered lists', (tester) async {
    final initialLists = [
      InventoryList(1, 'Kitchen', sortOrder: 0),
      InventoryList(2, 'Pantry', sortOrder: 1),
      InventoryList(3, 'Open', type: 'OPEN', sortOrder: 2),
    ];

    when(() => mockListService.all()).thenAnswer((_) async => initialLists);
    when(() => mockItemService.all(any())).thenAnswer((_) async => []);
    when(() => mockListService.reorder(any())).thenAnswer(
      (_) async => [
        InventoryList(2, 'Pantry', sortOrder: 0),
        InventoryList(1, 'Kitchen', sortOrder: 1),
        InventoryList(3, 'Open', type: 'OPEN', sortOrder: 2),
      ],
    );

    await tester.pumpWidget(TestWrapper(
      child: InventoryListRoute(logout: () async {}),
    ));
    await tester.pumpAndSettle();

    final reorderable =
        tester.widget<ReorderableListView>(find.byType(ReorderableListView));
    reorderable.onReorder!(0, 2);
    await tester.pumpAndSettle();

    verify(() => mockListService.reorder([2, 1, 3])).called(1);
  });
}
