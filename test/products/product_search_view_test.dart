// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/models/product.dart';

import 'package:inoventory_ui/services/product/product_service_interface.dart';
import 'package:inoventory_ui/views/product/product_search_view.dart';

class FakeProductService implements ProductService {
  final List<Product> _products = [
    Product("0", "Nutella", ean: "3017620425035"),
    Product("1", "Coca-Cola 1L", ean: "5449000054227")
  ];

  @override
  Future<List<Product>> search(String query) async {
    return _products.where((p) => p.ean == query).toList();
  }

  @override
  Future<Product> add(Product product) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> all() {
    // TODO: implement all
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(String productId) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<Product> update(String productId, Product product) {
    // TODO: implement update
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('ProductSearchView', (tester) async {
    final productService = FakeProductService();
    final InventoryList list = InventoryList("0", "rudy", "pantry");

    // Build the ProductSearchView widget
    await tester.pumpWidget(MaterialApp(
      home: ProductSearchView(initialSearchValue: "3017620425035", productService: productService, list: list),
    ));
    await tester.pump();


    // Verify that the products are displayed
    expect(find.text('Nutella'), findsOneWidget);
  });
}