import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/routes/product_detail_route.dart';
import 'package:inoventory_ui/products/widgets/add_product.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/inventory/items/widgets/add_item.dart';
import 'package:inoventory_ui/settings/off_settings_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  late MockProductService mockProductService;
  late MockOffSettingsService mockOffSettingsService;

  setUp(() {
    mockProductService = MockProductService();
    mockOffSettingsService = MockOffSettingsService();
    when(() => mockOffSettingsService.loadContributionSettings()).thenAnswer(
      (_) async =>
          const OffContributionSettings(region: 'world', language: 'en'),
    );
    setupMockGetIt(
      mockProductService: mockProductService,
      mockOffSettingsService: mockOffSettingsService,
    );

    registerFallbackValue(Product('1', 'Test', ean: '1'));
  });

  testWidgets('AddProductView validates and creates product', (tester) async {
    when(
      () => mockProductService.upsertToOpenFoodFacts(
        any(),
        any(),
        language: any(named: 'language'),
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

    expect(find.text('Please enter a product name'), findsNothing);
    expect(find.text('Please enter a brand'), findsNothing);
    expect(find.text('Please enter a quantity or weight'), findsNothing);

    await tester.enterText(
        find.byType(TextFormField).at(1), 'My Awesome Product');
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
        language: 'en',
        region: 'world',
      ),
    ).called(1);
  });

  testWidgets('AddProductView keeps entered values after submission error',
      (tester) async {
    when(
      () => mockProductService.upsertToOpenFoodFacts(
        any(),
        any(),
        language: any(named: 'language'),
        region: any(named: 'region'),
      ),
    ).thenThrow(Exception('timeout while uploading'));

    await tester.pumpWidget(TestWrapper(
      child: Scaffold(
        body: AddProductView(
          barcode: '404',
          onCancelProductAddition: () {},
        ),
      ),
    ));

    await tester.enterText(
        find.byType(TextFormField).at(1), 'My Awesome Product');
    await tester.enterText(find.byType(TextFormField).at(2), 'My Brand');
    await tester.enterText(find.byType(TextFormField).at(3), '500g');

    await tester
        .ensureVisible(find.widgetWithText(ElevatedButton, 'Add Product'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Product'));
    await tester.pumpAndSettle();

    expect(find.textContaining('timeout while uploading'), findsOneWidget);
    expect(find.text('My Awesome Product'), findsOneWidget);
    expect(find.text('My Brand'), findsOneWidget);
    expect(find.text('500g'), findsOneWidget);
    expect(find.byType(AddProductView), findsOneWidget);
  });

  testWidgets('AddItemView barcode opens product details', (tester) async {
    final product = Product('1', 'Milk', ean: '123', brands: 'Brand X');
    final list = InventoryList(1, 'Test List');

    await tester.pumpWidget(TestWrapper(
      child: AddItemView(product, list),
    ));

    await tester.tap(find.text('123'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailRoute), findsOneWidget);
    expect(find.text('Milk'), findsWidgets);
  });
}
