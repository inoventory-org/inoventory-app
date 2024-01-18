import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/items/widgets/item_widget.dart';

class GroupedInventoryListWidget extends StatelessWidget {
  final Map<String, List<ItemWrapper>> groupedItemWrappers;
  final Future<bool> Function(ItemWrapper itemWrapper) onDelete;
  final Future<void> Function(ItemWrapper itemWrapper) onEdit;

  const GroupedInventoryListWidget(
    this.groupedItemWrappers,
    this.onDelete,
    this.onEdit, {
    super.key,
  });

  TextStyle _getCategoryHeaderStyle(BuildContext context) {
    return TextStyle(
      color: Colors.white,
      backgroundColor: Theme.of(context).colorScheme.surface,
      fontSize: 28,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.only(bottom: 60.0),
        children: ListTile.divideTiles(
            context: context,
            tiles: groupedItemWrappers.entries.map((element) {
              final categoryName = element.key;
              final itemWrappers = element.value;
              return ExpansionTile(
                  initiallyExpanded: true,
                  title: categoryName == "null" ? Text("Uncategorized", style: _getCategoryHeaderStyle(context)) : Text(categoryName, style: _getCategoryHeaderStyle(context)),
                  children: ListTile.divideTiles(
                          context: context,
                          tiles: itemWrappers.map((itemWrapper) {
                            return InventoryItemWidget(itemWrapper, onDelete);
                          }).toList())
                      .toList());
            })).toList());
  }
}
