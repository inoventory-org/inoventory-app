import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/models/inventory_list_item.dart';

class InventoryListService {

  final List<InventoryList> _lists = [
    InventoryList("0", "rudy", "Pantry"),
    InventoryList("1", "rudy", "fridge"),
    InventoryList("2", "soeren", "garage"),
  ];

  final Map<String, List<InventoryListItem>> listToItems = {
    "0": [],
    "1": [],
    "2": []
  };

  List<InventoryList> all() {
    return _lists;
  }

  List<InventoryListItem> getListItems(InventoryList list) {
    print(list.id);
    print(listToItems[list.id]);
    return listToItems[list.id] ?? [];
  }

  void addItemToList(InventoryList list, InventoryListItem item) {
    listToItems[list.id]?.add(item);
  }

}