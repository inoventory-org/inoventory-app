import 'package:flutter/material.dart';
import 'inventory_item.dart';
import 'dart:developer' as developer;

class InventoryItemWidget extends StatefulWidget {
  final InventoryListItemWrapper itemWrapper;
  final Future<void> Function(int listId, int itemId) onDelete;

  const InventoryItemWidget(
    this.itemWrapper,
    this.onDelete, {
    Key? key,
  }) : super(key: key);

  @override
  State<InventoryItemWidget> createState() => _InventoryItemWidgetState();
}

class _InventoryItemWidgetState extends State<InventoryItemWidget> {
  bool isDeleting = false;

  Future<void> onDismissed(DismissDirection direction) async {
    if (!isDeleting) {
      print("Deleting item");

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        isDeleting = true;
        await widget.onDelete(
            widget.itemWrapper.listId, widget.itemWrapper.items.first.id);
        scaffoldMessenger.showSnackBar(const SnackBar(
            content: Text("Successfully deleted item!",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text("Error deleting item: ${e.toString()}",
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red));
        
        developer.log("Could not delete item", error: e);
      } finally {
        isDeleting = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.itemWrapper.productEan),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await onDismissed(direction);
      },
      resizeDuration: null,
      child: ListTile(
        // leading: icon
        title: Text(
          widget.itemWrapper.displayName ?? widget.itemWrapper.productEan,
          style: const TextStyle(fontSize: 18),
        ),
        subtitle: Text(
          widget.itemWrapper.productEan,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: widget.itemWrapper.quantity > 1
            ? Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    "Quantity: ${widget.itemWrapper.quantity.toString()}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
