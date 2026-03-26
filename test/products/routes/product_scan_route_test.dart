import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/ean/scanner.dart';
import 'package:inoventory_ui/inventory/items/widgets/add_item.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/routes/product_scan_route.dart';
import 'package:inoventory_ui/products/widgets/add_product.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  late MockProductService mockProductService;
  late MockItemService mockItemService;
  late InventoryList dummyList;

  setUp(() {
    mockProductService = MockProductService();
    mockItemService = MockItemService();
    setupMockGetIt(
      mockProductService: mockProductService, 
      mockItemService: mockItemService
    );

    dummyList = InventoryList(1, 'Test List');
    registerFallbackValue(Item(0, 1, '123', 'Milk'));
  });

  testWidgets('ProductScanRoute launches AddItemView for known product', (tester) async {
    final product = Product('123', 'Milk', ean: '123', brands: 'Brand X');

    when(() => mockProductService.search('123', fresh: any(named: 'fresh')))
        .thenAnswer((_) async => [product]);

    await tester.pumpWidget(TestWrapper(
      child: ProductScanRoute(inventoryList: dummyList),
    ));

    // Get the scanner widget and manually trigger the scan event since camera won't run headless
    final scannerWidget = tester.widget<BarcodeScannerWidget>(find.byType(BarcodeScannerWidget));
    
    // Create fake barcode capture
    final fakeBarcode = Barcode(rawValue: '123');
    final fakeCapture = BarcodeCapture(barcodes: [fakeBarcode]);

    await scannerWidget.onDetect(fakeCapture);
    await tester.pumpAndSettle();

    // Valid product means we show AddItemView
    expect(find.byType(AddItemView), findsOneWidget);
    expect(find.byType(AddProductView), findsNothing);
  });

  testWidgets('ProductScanRoute launches AddProductView for unknown product', (tester) async {
    when(() => mockProductService.search('404', fresh: any(named: 'fresh')))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(TestWrapper(
      child: ProductScanRoute(inventoryList: dummyList),
    ));

    final scannerWidget = tester.widget<BarcodeScannerWidget>(find.byType(BarcodeScannerWidget));
    
    final fakeBarcode = Barcode(rawValue: '404');
    final fakeCapture = BarcodeCapture(barcodes: [fakeBarcode]);

    await scannerWidget.onDetect(fakeCapture);
    await tester.pumpAndSettle();

    // Unknown product means we show AddProductView
    expect(find.byType(AddProductView), findsOneWidget);
    expect(find.byType(AddItemView), findsNothing);
  });
}
