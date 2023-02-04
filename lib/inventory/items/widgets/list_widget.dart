import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/items/widgets/item_widget.dart';

class InventoryListWidget extends StatelessWidget {
  final List<ItemWrapper> itemWrappers;
  final Future<bool> Function(ItemWrapper itemWrapper) onDelete;
  final Future<void> Function(ItemWrapper itemWrapper) onEdit;

  const InventoryListWidget(
      {Key? key,
      required this.itemWrappers,
      required this.onDelete,
      required this.onEdit})
      : super(key: key);

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