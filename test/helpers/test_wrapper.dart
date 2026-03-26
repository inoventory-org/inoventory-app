import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_service.dart';
import 'package:inoventory_ui/products/open_food_facts_service.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:mocktail/mocktail.dart';
import 'mocks.dart';

class TestWrapper extends StatelessWidget {
  final Widget child;

  const TestWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: child,
      theme: ThemeData.light(),
    );
  }
}

void setupMockGetIt({
  MockItemService? mockItemService,
  MockInventoryListService? mockInventoryListService,
  MockProductService? mockProductService,
  MockOpenFoodFactsService? mockOpenFoodFactsService,
}) {
  GetIt.I.reset();
  GetIt.I.registerSingleton<ItemService>(mockItemService ?? MockItemService());
  GetIt.I.registerSingleton<InventoryListService>(
      mockInventoryListService ?? MockInventoryListService());
  GetIt.I.registerSingleton<ProductService>(
      mockProductService ?? MockProductService());
  GetIt.I.registerSingleton<OpenFoodFactsService>(
      mockOpenFoodFactsService ?? MockOpenFoodFactsService());
}
