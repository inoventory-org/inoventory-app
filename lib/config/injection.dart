import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:inoventory_ui/config/http_config.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_service.dart';
import 'package:inoventory_ui/notifications/push_notification_service.dart';
import 'package:inoventory_ui/products/open_food_facts_service.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/settings/off_settings_service.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  final dio = Dio();
  const secureStorage = FlutterSecureStorage();
  dio.interceptors.add(InoventoryTokenInterceptor(dio));
  getIt.registerSingleton<Dio>(dio);
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);
  getIt.registerLazySingleton<OffSettingsService>(
      () => OffSettingsServiceImpl(getIt<FlutterSecureStorage>()));
  getIt.registerLazySingleton<ProductService>(
      () => ProductServiceImpl(getIt<Dio>()));
  getIt.registerLazySingleton<InventoryListService>(
      () => InventoryListServiceImpl(getIt<Dio>()));
  getIt.registerLazySingleton<ItemService>(() => ItemServiceImpl(getIt<Dio>()));
  getIt.registerLazySingleton<PushNotificationService>(
      () => PushNotificationService(getIt<Dio>()));

  // OpenFoodFactsService is kept for direct reads via the OFF Dart SDK (getProduct()).
  // Product writes/uploads now go through the Inoventory backend (ProductService.upsertToOpenFoodFacts).
  // Uncomment the line below to re-enable the direct OFF SDK approach for writes if needed in the future.
  getIt.registerLazySingleton<OpenFoodFactsService>(
      () => OpenFoodFactsServiceImpl());
}
