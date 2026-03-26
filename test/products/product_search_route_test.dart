import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/routes/product_search_route.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/test_wrapper.dart';

void main() {
  late MockProductService mockProductService;
  late InventoryList dummyList;

  setUp(() {
    mockProductService = MockProductService();
    setupMockGetIt(mockProductService: mockProductService);

    dummyList = InventoryList(1, 'Test List');
  });

  testWidgets('ProductSearchRoute displays products from service', (tester) async {
    final product = Product('123', 'Milk', ean: '123', brands: 'Brand X');
    final product2 = Product('124', 'Eggs', ean: '124', brands: 'Brand Y');

    when(() => mockProductService.all()).thenAnswer((_) async => []);
    when(() => mockProductService.search(any(), fresh: any(named: 'fresh')))
        .thenAnswer((_) async => [product, product2]);

    await tester.pumpWidget(TestWrapper(
      child: ProductSearchRoute(
        initialSearchValue: 'Milk',
        list: dummyList,
        productService: mockProductService,
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsWidgets);
  });
}
