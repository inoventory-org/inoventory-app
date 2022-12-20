import 'package:inoventory_ui/models/inventory_list.dart';

class InventoryListService {

  List<InventoryList> get_all() {
    return [
      InventoryList("0", "rudy", "Pantry"),
      InventoryList("1", "rudy", "fridge"),
      InventoryList("2", "soeren", "garage"),
    ];
  }
}