import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_service.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/inventory/items/routes/item_detail_route.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_network_image.dart';

class InventoryItemWidget extends StatelessWidget {
  final ItemWrapper itemWrapper;
  final Future<bool> Function(ItemWrapper itemWrapper)? onDelete;
  final Future<void> Function(ItemWrapper itemWrapper)? onEdit;
  final bool focusExpiring;
  final bool isOpenList;

  final ProductService _productService = getIt<ProductService>();
  final InventoryListService _inventoryListService = getIt<InventoryListService>();

  InventoryItemWidget(
    this.itemWrapper,
    this.onDelete, {
    this.onEdit,
    this.focusExpiring = false,
    this.isOpenList = false,
    super.key,
  });

  String? _getNextExpiring() {
    List<String?> expirationDates = itemWrapper.items.where((element) => element.expirationDate != null).map((e) => e.expirationDate).toList()..sort();
    return expirationDates.firstOrNull;
  }

  bool _isExpiringSoon() {
    final nextExpiring = _getNextExpiring();
    if (nextExpiring == null) return false;
    try {
      final date = DateTime.parse(nextExpiring);
      return date.difference(DateTime.now()).inDays <= 30;
    } catch (_) {
      return false;
    }
  }

  bool _hasExpiredItem() {
    return itemWrapper.items.any((item) {
      if (item.expirationDate == null) {
        return false;
      }
      final expiration = DateTime.tryParse(item.expirationDate!);
      if (expiration == null) {
        return false;
      }
      return expiration.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    });
  }

  String? _getOpenedSince() {
    final openedAt = itemWrapper.items
        .map((item) => item.openedAt)
        .whereType<String>()
        .sorted()
        .firstOrNull;
    if (openedAt == null) {
      return null;
    }
    final openedDate = DateTime.tryParse(openedAt);
    if (openedDate == null) {
      return openedAt;
    }
    final days = DateTime.now().difference(openedDate).inDays;
    if (days >= 60) {
      final months = (days / 30).floor();
      return "Opened $months month${months == 1 ? '' : 's'} ago";
    }
    if (days >= 14) {
      final weeks = (days / 7).floor();
      return "Opened $weeks week${weeks == 1 ? '' : 's'} ago";
    }
    return "Opened $days day${days == 1 ? '' : 's'} ago";
  }

  @override
  Widget build(BuildContext context) {
    final bool expiringSoon = focusExpiring && _isExpiringSoon();
    final bool expiredOpenItem = isOpenList && _hasExpiredItem();
    return Card(
      color: expiredOpenItem
          ? Theme.of(context).colorScheme.errorContainer
          : expiringSoon
              ? Theme.of(context).colorScheme.errorContainer
              : null,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Dismissible(
        key: Key(itemWrapper.productEan),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Theme.of(context).colorScheme.secondary,
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
            await navigator.push(MaterialPageRoute(builder: (context) => ItemDetailRoute(itemWrapper: itemWrapper, list: inventoryList)));
            if (onEdit != null) {
              await onEdit!(itemWrapper);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: isOpenList
                        ? Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.7)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: itemWrapper.thumbUrl != null
                      ? InoventoryNetworkImage(url: itemWrapper.thumbUrl!)
                      : Icon(
                          isOpenList ? Icons.lock_open : Icons.inventory_2_outlined,
                          color: (isOpenList
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context).colorScheme.primary)
                              .withOpacity(0.7),
                        ),
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
                            Icon(Icons.event_busy, size: 14, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              "Expires: ${_getNextExpiring()}",
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      if (isOpenList && _getOpenedSince() != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: expiredOpenItem
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getOpenedSince()!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: expiredOpenItem
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context).colorScheme.tertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
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
