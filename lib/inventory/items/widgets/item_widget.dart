import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_service.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/routes/product_detail_route.dart';

class InventoryItemWidget extends StatelessWidget {
  final ItemWrapper itemWrapper;
  final Future<bool> Function(ItemWrapper itemWrapper)? onDelete;

  final ProductService _productService = getIt<ProductService>();
  final InventoryListService _inventoryListService = getIt<InventoryListService>();

  InventoryItemWidget(
    this.itemWrapper,
    this.onDelete, {
    super.key,
  });

  String? _getNextExpiring() {
    List<String?> expirationDates = itemWrapper.items.where((element) => element.expirationDate != null).map((e) => e.expirationDate).toList()..sort();
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
      confirmDismiss: (direction) => onDelete != null ? onDelete!(itemWrapper) : doNothing(),
      resizeDuration: null,
      child: ListTile(
          onTap: () async {
            final navigator = Navigator.of(context);
            InventoryList inventoryList = await _inventoryListService.get(itemWrapper.listId);
            Product product = (await _productService.search(itemWrapper.productEan)).first;
            navigator.push(MaterialPageRoute(builder: (context) => ProductDetailRoute(product: product, list: inventoryList)));
          },
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
            child: itemWrapper.thumbUrl == null ? const Icon(Icons.image) : null,
          ),
          title: Text(
            itemWrapper.displayName,
            style: const TextStyle(fontSize: 18),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemWrapper.productEan,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (_getNextExpiring() != null)
                Text(
                  "Next items expires on: ${_getNextExpiring()}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
            ],
          ),
          trailing: itemWrapper.quantity > 1 ? _QuantityWidget(itemWrapper.quantity) : null),
    );
  }

  Future<bool?> doNothing() async {
    return false;
  }
}

class _QuantityWidget extends StatelessWidget {
  const _QuantityWidget(this._quantity);

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
