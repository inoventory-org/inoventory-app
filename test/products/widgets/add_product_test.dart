import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/products/widgets/add_product.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  late MockOpenFoodFactsService mockOpenFoodFactsService;

  setUp(() {
    mockOpenFoodFactsService = MockOpenFoodFactsService();
    setupMockGetIt(mockOpenFoodFactsService: mockOpenFoodFactsService);
    
    // Fallback for Product parameter of addProduct
    registerFallbackValue(Product('1', 'Test', ean: '1'));
  });

  testWidgets('AddProductView validates and creates product', (tester) async {
    when(() => mockOpenFoodFactsService.addProduct(any(), any()))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(TestWrapper(
      child: Scaffold(
        body: AddProductView(
          barcode: '404',
          onCancelProductAddition: () {},
        ),
      ),
    ));

    // Press Add Product immediately
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Add Product'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Product'));
    await tester.pumpAndSettle();

    // Verify validation errors appear
    expect(find.text('Please enter a product name'), findsOneWidget);
    expect(find.text('Please enter a brand'), findsOneWidget);
    expect(find.text('Please enter a quantity or weight'), findsOneWidget);

    // Fill the fields. The text fields are decorated with labelText, so we can find them by that text.
    await tester.enterText(find.descendant(of: find.byType(TextFormField), matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Product Name')), 'My Awesome Product');
    await tester.enterText(find.descendant(of: find.byType(TextFormField), matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Brand')), 'My Brand');
    await tester.enterText(find.descendant(of: find.byType(TextFormField), matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Quantity and Weight')), '500g');
    
    // Tap Add Product again
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Add Product'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Product'));
    await tester.pumpAndSettle();

    // Verify the service was called to add the product
    verify(() => mockOpenFoodFactsService.addProduct(any(), any())).called(1);
  });
}
