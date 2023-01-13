import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/lists/models/item_wrapper.dart';

class InventoryItemWidget extends StatelessWidget {
  final ItemWrapper itemWrapper;

  const InventoryItemWidget(
    this.itemWrapper, {
    Key? key,
  }) : super(key: key);

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
      //confirmDismiss: (direction) => onDelete(itemWrapper),
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
