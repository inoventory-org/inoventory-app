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
import 'package:inoventory_ui/shared/widgets/inoventory_network_image.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Dismissible(
        key: Key(itemWrapper.productEan),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Theme.of(context).colorScheme.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onError, size: 28),
        ),
        confirmDismiss: (direction) => onDelete != null ? onDelete!(itemWrapper) : doNothing(),
        resizeDuration: null,
        child: InkWell(
          onTap: () async {
            final navigator = Navigator.of(context);
            InventoryList inventoryList = await _inventoryListService.get(itemWrapper.listId);
            Product product = (await _productService.search(itemWrapper.productEan)).first;
            navigator.push(MaterialPageRoute(builder: (context) => ProductDetailRoute(product: product, list: inventoryList)));
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: itemWrapper.thumbUrl != null
                      ? InoventoryNetworkImage(url: itemWrapper.thumbUrl!)
                      : Icon(Icons.inventory_2_outlined, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemWrapper.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        itemWrapper.productEan,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              letterSpacing: 1.2,
                            ),
                      ),
                      if (_getNextExpiring() != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.event_busy, size: 14, color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 4),
                            Text(
                              "Expires: ${_getNextExpiring()}",
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                if (itemWrapper.quantity > 1) ...[
                  const SizedBox(width: 8),
                  _QuantityWidget(itemWrapper.quantity),
                ],
              ],
            ),
          ),
        ),
      ),
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
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tag, size: 14, color: Theme.of(context).colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            "$_quantity",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}
