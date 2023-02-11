import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/items/widgets/item_widget.dart';

class GroupedInventoryListWidget extends StatefulWidget {
  final Map<String, List<ItemWrapper>> groupedItemWrappers;
  final Future<bool> Function(ItemWrapper itemWrapper) onDelete;
  final Future<void> Function(ItemWrapper itemWrapper) onEdit;

  const GroupedInventoryListWidget(
    this.groupedItemWrappers,
    this.onDelete,
    this.onEdit, {
    Key? key,
  }) : super(key: key);

  @override
  State<GroupedInventoryListWidget> createState() => _GroupedInventoryListWidgetState();
}

class _GroupedInventoryListWidgetState extends State<GroupedInventoryListWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView(
        children: ListTile.divideTiles(
            context: context,
            tiles: widget.groupedItemWrappers.entries.map((element) {
              final categoryName = element.key;
              final itemWrappers = element.value;
              return ExpansionTile(
                  title: Text(categoryName),
                  children: itemWrappers.map((itemWrapper) {
                    return InventoryItemWidget(itemWrapper, widget.onDelete);
                  }).toList()
              );
            })).toList());
  }
}
