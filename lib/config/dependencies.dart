import 'package:inoventory_ui/services/inventory_list/inventory_list_service.dart';
import 'package:inoventory_ui/services/product/product_service_interface.dart';
import 'package:inoventory_ui/services/product/product_service_impl.dart';

abstract class Dependencies {
  static InventoryListService inoventoryListService = InventoryListService();
  static ProductService productService = ProductServiceImpl();
}