import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:inoventory_ui/inventory/items/widgets/add_item.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/shared/widgets/expiry_date_input.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_wrapper.dart';

void main() {
  late MockItemService mockItemService;
  late Product dummyProduct;
  late InventoryList dummyList;

  setUp(() {
    mockItemService = MockItemService();
    setupMockGetIt(mockItemService: mockItemService);

    dummyList = InventoryList(1, 'Test List');
    dummyProduct = Product('123', 'Milk', ean: '123', brands: 'Brand X');
    
    registerFallbackValue(Item(0, 1, '123', 'Milk'));
  });

  testWidgets('AddItemView increments amount and fires expected add calls', (tester) async {
    when(() => mockItemService.add(any())).thenAnswer((_) async => Item(1, 1, '123', 'Milk'));

    await tester.pumpWidget(TestWrapper(
      child: AddItemView(dummyProduct, dummyList),
    ));

    await tester.pumpAndSettle();

    // Initially 1 amount
    expect(find.byType(ExpiryDateEntry), findsOneWidget);

    // Tap increase amount
    final increaseBtn = find.byIcon(Icons.add);
    await tester.ensureVisible(increaseBtn);
    await tester.tap(increaseBtn);
    await tester.pumpAndSettle();

    // Now 2 amounts (2 expiry entries)
    expect(find.byType(ExpiryDateEntry), findsNWidgets(2));

    // Tap the FAB to save
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    // add() should be called twice since amount is 2
    verify(() => mockItemService.add(any())).called(2);
  });
}
