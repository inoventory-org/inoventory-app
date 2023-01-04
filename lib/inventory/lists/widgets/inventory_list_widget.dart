import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/inventory_item.dart';

class InventoryListWidget extends StatelessWidget {
  final List<InventoryListItemWrapper> itemWrappers;
  final Future<void> Function(int listId, int itemId) onDelete;
  final Future<void> Function(InventoryListItemWrapper itemWrapper) onEdit;

  const InventoryListWidget({Key? key, required this.itemWrappers, required this.onDelete, required this.onEdit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: ListTile.divideTiles(
            context: context,
            tiles: itemWrappers.map((itemWrapper) {
              return ListTile(
                // leading: icon
                title: Text(
                  itemWrapper.displayName ?? itemWrapper.productEan,
                  style: const TextStyle(fontSize: 18),
                ),
                subtitle: Text(
                  itemWrapper.productEan,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                trailing: itemWrapper.quantity > 1 ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      "Quantity: ${itemWrapper.quantity.toString()}",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ) : null,
              );
            })).toList());
  }
}
