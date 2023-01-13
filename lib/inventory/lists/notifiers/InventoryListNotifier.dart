import 'package:flutter/cupertino.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inventory/lists/items/item_service.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';

class InventoryListNotifier extends ValueNotifier<InventoryList> {
  InventoryListNotifier(super.value);

  final itemService = getIt<ItemService>();

  Future<void> initialize() async {
    var items = await itemService.all(value.id);
    value.items = items;
    notifyListeners();
  }
}
