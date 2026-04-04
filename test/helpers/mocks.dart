import 'package:dio/dio.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_service.dart';
import 'package:inoventory_ui/products/open_food_facts_service.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/settings/off_settings_service.dart';
import 'package:mocktail/mocktail.dart';

class MockItemService extends Mock implements ItemService {}

class MockInventoryListService extends Mock implements InventoryListService {}

class MockProductService extends Mock implements ProductService {}

class MockOpenFoodFactsService extends Mock implements OpenFoodFactsService {}

class MockOffSettingsService extends Mock implements OffSettingsService {}

class MockDio extends Mock implements Dio {}
