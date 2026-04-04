import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:inoventory_ui/config/http_config.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_service.dart';
import 'package:inoventory_ui/notifications/push_notification_service.dart';
import 'package:inoventory_ui/products/open_food_facts_service.dart';
import 'package:inoventory_ui/products/product_service.dart';


final getIt = GetIt.instance;

void configureDependencies() {
  final dio = Dio();
  dio.interceptors.add(InoventoryTokenInterceptor(dio));
  getIt.registerSingleton<Dio>(dio);
  getIt.registerLazySingleton<ProductService>(() => ProductServiceImpl(getIt<Dio>()));
  getIt.registerLazySingleton<InventoryListService>(() => InventoryListServiceImpl(getIt<Dio>()));
  getIt.registerLazySingleton<ItemService>(() => ItemServiceImpl(getIt<Dio>()));
  getIt.registerLazySingleton<OpenFoodFactsService>(() => OpenFoodFactsServiceImpl());
  getIt.registerLazySingleton<PushNotificationService>(() => PushNotificationService(getIt<Dio>()));
  }
