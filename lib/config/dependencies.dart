import 'package:inoventory_ui/services/inventory_list_service.dart';
import 'package:inoventory_ui/services/item_service.dart';
import 'package:inoventory_ui/services/product_service.dart';

abstract class Dependencies {
  static InventoryListService inoventoryListService = InventoryListServiceImpl();
  static ProductService productService = ProductServiceImpl();
  static ItemService itemService = ItemServiceImpl();


}