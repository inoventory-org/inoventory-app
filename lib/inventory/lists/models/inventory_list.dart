import 'package:inoventory_ui/inventory/lists/models/item_wrapper.dart';

class InventoryList {
  final int id;
  final String name;
  List<ItemWrapper> items;

  InventoryList(this.id, this.name, {List<ItemWrapper>? items})
      : items = items ?? [];

  factory InventoryList.fromJson(Map<String, dynamic> json) {
    return InventoryList(
      json['id'],
      json['name'],
    );
  }
}
