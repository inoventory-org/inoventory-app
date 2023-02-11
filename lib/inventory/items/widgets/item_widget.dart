import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';

class InventoryItemWidget extends StatelessWidget {
  final ItemWrapper itemWrapper;
  final Future<bool> Function(ItemWrapper itemWrapper) onDelete;

  const InventoryItemWidget(
    this.itemWrapper,
    this.onDelete, {
    Key? key,
  }) : super(key: key);

  String? _getNextExpiring() {
    List<String?> expirationDates = itemWrapper.items
        .where((element) => element.expirationDate != null)
        .map((e) => e.expirationDate)
        .toList()..sort();
    return expirationDates.firstOrNull;
  }
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(itemWrapper.productEan),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.all(25),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) => onDelete(itemWrapper),
      resizeDuration: null,
      child: ListTile(
          leading: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              image: itemWrapper.thumbUrl != null
                  ? DecorationImage(
                      image: NetworkImage(itemWrapper.thumbUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child:
                itemWrapper.thumbUrl == null ? const Icon(Icons.image) : null,
          ),
          title: Text(
            itemWrapper.displayName ?? itemWrapper.productEan,
            style: const TextStyle(fontSize: 18),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemWrapper.productEan,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (_getNextExpiring() != null) Text(
                "Next items expires on: ${_getNextExpiring()}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
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
