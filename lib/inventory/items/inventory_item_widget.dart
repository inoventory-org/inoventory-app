import 'package:flutter/material.dart';
import 'inventory_item.dart';

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
        if (!isDeleting) {
          print("Deleting item");
          try {
            isDeleting = true;
            await widget.onDelete(
                widget.itemWrapper.listId, widget.itemWrapper.items.first.id);
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(const SnackBar(
                content: Text("Successfully deleted item!",
                    style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green));
          } catch (e) {
            print(e);
          } finally {
            isDeleting = false;
          }
        }
      },
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
