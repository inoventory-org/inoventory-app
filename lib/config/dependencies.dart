import 'package:inoventory_ui/services/auth_service.dart';
import 'package:dio/dio.dart';

import 'package:inoventory_ui/services/inventory_list_service.dart';
import 'package:inoventory_ui/services/item_service.dart';
import 'package:inoventory_ui/services/product_service.dart';


abstract class Dependencies {
  static Dio dio = Dio();
  static InventoryListService inoventoryListService = InventoryListServiceImpl(dio);
  static ProductService productService = ProductServiceImpl(dio);
  static ItemService itemService = ItemServiceImpl(dio);
  static AuthService authService = OIDCAuthService(dio);
}