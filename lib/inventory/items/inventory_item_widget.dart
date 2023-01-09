import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import 'inventory_item_list_widget.dart';

class InventoryItemWidget extends StatelessWidget {
  final InventoryListItemWrapper itemWrapper;
  final Future<void> Function(int itemId) onDelete;

  const InventoryItemWidget(
    this.itemWrapper,
    this.onDelete, {
    Key? key,
  }) : super(key: key);

  Future<void> onDismissed(
      BuildContext context, DismissDirection direction) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final int? itemId = await getItemIdToDelete(context);
    if (itemId == null) {
      return;
    }

    try {
      await onDelete(itemId);

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

  Future<int?> getItemIdToDelete(BuildContext context) async {
    if (itemWrapper.items.map((e) => e.expirationDate).toSet().length == 1) {
      return itemWrapper.items.first.id;
    }

    return await showDialog<int>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Choose item"),
            content: const Text("Which item do you want to remove?"),
            actions: itemWrapper.items
                .map((e) => Center(
                  child: TextButton(
                        onPressed: () => Navigator.pop(context, e.id),
                        child: Text(e.expirationDate ?? "<no expiration date>"),
                      ),
                ))
                .toList(),
          );
        });
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
