import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/widgets/add_product.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  late MockProductService mockProductService;

  setUp(() {
    mockProductService = MockProductService();
    setupMockGetIt(mockProductService: mockProductService);

    registerFallbackValue(Product('1', 'Test', ean: '1'));
  });

  testWidgets('AddProductView validates and creates product', (tester) async {
    when(
      () => mockProductService.upsertToOpenFoodFacts(
        any(),
        any(),
        region: any(named: 'region'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(TestWrapper(
      child: Scaffold(
        body: AddProductView(
          barcode: '404',
          onCancelProductAddition: () {},
        ),
      ),
    ));

    // Press Add Product immediately
    await tester
        .ensureVisible(find.widgetWithText(ElevatedButton, 'Add Product'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Product'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a product name'), findsOneWidget);
    expect(find.text('Please enter a brand'), findsNothing);
    expect(find.text('Please enter a quantity or weight'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(1), 'My Awesome Product');
    await tester.enterText(find.byType(TextFormField).at(2), 'My Brand');
    await tester.enterText(find.byType(TextFormField).at(3), '500g');

    await tester
        .ensureVisible(find.widgetWithText(ElevatedButton, 'Add Product'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Product'));
    await tester.pumpAndSettle();

    verify(
      () => mockProductService.upsertToOpenFoodFacts(
        any(
          that: isA<Product>()
              .having((p) => p.ean, 'ean', '404')
              .having((p) => p.name, 'name', 'My Awesome Product')
              .having((p) => p.brands, 'brands', 'My Brand')
              .having((p) => p.weight, 'weight', '500g'),
        ),
        any(that: isEmpty),
        region: 'world',
      ),
    ).called(1);
  });
}
