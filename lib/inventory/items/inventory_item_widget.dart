import 'package:flutter/material.dart';
import 'inventory_item.dart';
import 'dart:developer' as developer;

class InventoryItemWidget extends StatelessWidget {
  final InventoryListItemWrapper itemWrapper;
  final Future<void> Function(int listId, int itemId) onDelete;

  const InventoryItemWidget(
    this.itemWrapper,
    this.onDelete, {
    Key? key,
  }) : super(key: key);

  Future<void> onDismissed(
      BuildContext context, DismissDirection direction) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await onDelete(itemWrapper.listId, itemWrapper.items.first.id);

      scaffoldMessenger.showSnackBar(
          _getSnackBar("Successfully deleted item", Colors.green));
    } catch (e) {
      scaffoldMessenger
          .showSnackBar(_getSnackBar("Error deleting item: ", Colors.red));

      developer.log("Could not delete item", error: e);
    }
  }

  SnackBar _getSnackBar(String text, Color color) {
    TextStyle style = const TextStyle(color: Colors.white);

    return SnackBar(content: Text(text, style: style), backgroundColor: color);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(itemWrapper.productEan),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await onDismissed(context, direction);
      },
      resizeDuration: null,
      child: ListTile(
          // leading: icon
          title: Text(
            itemWrapper.displayName ?? itemWrapper.productEan,
            style: const TextStyle(fontSize: 18),
          ),
          subtitle: Text(
            itemWrapper.productEan,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          trailing: itemWrapper.quantity > 1
              ? _QuantityWidget(itemWrapper.quantity)
              : null),
    );
  }
}

class _QuantityWidget extends StatelessWidget {
  const _QuantityWidget(this._quantity, {Key? key}) : super(key: key);

  final int _quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Text(
          "Quantity: $_quantity",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
