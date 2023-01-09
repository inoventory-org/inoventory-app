import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/inventory_item.dart';
import 'package:inoventory_ui/inventory/items/widgets/inventory_item_widget.dart';


class InventoryListWidget extends StatelessWidget {
  final List<InventoryListItemWrapper> itemWrappers;
  final Future<void> Function(int itemId) onDelete;
  final Future<void> Function(InventoryListItemWrapper itemWrapper) onEdit;

  const InventoryListWidget({Key? key, required this.itemWrappers, required this.onDelete, required this.onEdit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: ListTile.divideTiles(
            context: context,
            tiles: itemWrappers.map((itemWrapper) {
              return InventoryItemWidget(itemWrapper, onDelete);
            })).toList());
  }
}