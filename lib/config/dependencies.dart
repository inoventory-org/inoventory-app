import 'package:http/http.dart';
import 'package:inoventory_ui/services/auth_service.dart';


import 'package:inoventory_ui/services/inventory_list_service.dart';
import 'package:inoventory_ui/services/item_service.dart';
import 'package:inoventory_ui/services/product_service.dart';


abstract class Dependencies {
  static Client httpClient = Client();
  static InventoryListService inoventoryListService = InventoryListServiceImpl(client: httpClient);
  static ProductService productService = ProductServiceImpl();
  static ItemService itemService = ItemServiceImpl();
  // static FlutterAppAuthService authService = FlutterAppAuthService(httpClient);
  static AuthService authService = OIDCAuthService(httpClient);

}