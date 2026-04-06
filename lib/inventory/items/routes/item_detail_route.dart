import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/expiry_scan/expiry_date_picker.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/items/item_list_route.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_service.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/routes/product_detail_route.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_network_image.dart';

class ItemDetailRoute extends StatefulWidget {
  final ItemWrapper itemWrapper;
  final InventoryList list;

  const ItemDetailRoute({
    Key? key,
    required this.itemWrapper,
    required this.list,
  }) : super(key: key);

  @override
  State<ItemDetailRoute> createState() => _ItemDetailRouteState();
}

class _ItemDetailRouteState extends State<ItemDetailRoute> {
  late List<Item> items;
  final ItemService _itemService = getIt<ItemService>();
  final InventoryListService _listService = getIt<InventoryListService>();
  final ProductService _productService = getIt<ProductService>();

  @override
  void initState() {
    super.initState();
    items = List.from(widget.itemWrapper.items);
  }

  Future<void> _deleteItem(Item item) async {
    try {
      await _itemService.delete(widget.list.id, item.id);
      setState(() {
        items.remove(item);
      });
      if (items.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Item deleted"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error deleting item: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openItem(Item item) async {
    String? expirationDate = item.expirationDate;
    if (expirationDate == null) {
      expirationDate = await _pickExpiryDate(
        initialDate: DateTime.now(),
        helpText: "Select an expiration date for the opened item",
      );
      if (expirationDate == null) {
        return;
      }
    }

    try {
      await _itemService.open(widget.list.id, item.id,
          expirationDate: expirationDate);
      setState(() {
        items.remove(item);
      });
      if (!mounted) {
        return;
      }
      await _showMovedToOpenListSnackBar();
      if (items.isEmpty) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error opening item: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editExpirationDate(Item item) async {
    final initialDate = item.expirationDate != null
        ? DateTime.tryParse(item.expirationDate!)
        : null;
    final newDateOptions = await _pickExpiryDate(initialDate: initialDate);
    if (newDateOptions != null) {
      if (newDateOptions != item.expirationDate) {
        try {
          // Send updated values back so itemService recognizes them
          Item updatedItem = Item(
            item.id,
            item.listId,
            item.productEan,
            item.displayName,
            expirationDate: newDateOptions,
            openedAt: item.openedAt,
            imageUrl: item.imageUrl,
            thumbUrl: item.thumbUrl,
            tags: item.tags,
          );
          await _itemService.update(item.id, updatedItem);
          setState(() {
            item.expirationDate = newDateOptions;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Expiration date updated"),
                  backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("Error updating expiration date: $e"),
                  backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  Future<void> _editOpenedDate(Item item) async {
    final initialDate =
        item.openedAt != null ? DateTime.tryParse(item.openedAt!) : null;
    final newOpenedDate = await _pickCalendarDate(
      initialDate: initialDate ?? DateTime.now(),
      helpText: "Select the date this item was opened",
    );
    if (newOpenedDate == null || newOpenedDate == item.openedAt) {
      return;
    }

    try {
      final updatedItem = Item(
        item.id,
        item.listId,
        item.productEan,
        item.displayName,
        expirationDate: item.expirationDate,
        openedAt: newOpenedDate,
        imageUrl: item.imageUrl,
        thumbUrl: item.thumbUrl,
        tags: item.tags,
      );
      await _itemService.update(item.id, updatedItem);
      setState(() {
        item.openedAt = newOpenedDate;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Opened date updated"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error updating opened date: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _pickExpiryDate({
    DateTime? initialDate,
    String? helpText,
  }) async {
    return pickExpiryDate(
      context,
      initialDate: initialDate,
      helpText: helpText,
      scanTitle: 'Scan Expiry Date',
    );
  }

  Future<String?> _pickCalendarDate({
    DateTime? initialDate,
    String? helpText,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: helpText,
    );

    if (pickedDate == null) {
      return null;
    }
    return "${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
  }

  Future<void> _handleItemRemoval(Item item) async {
    if (widget.list.isOpenList) {
      await _deleteItem(item);
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "What do you want to do with this item?",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, 'open'),
                icon: const Icon(Icons.lock_open),
                label: const Text("Open Item"),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'checkout'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Check Out"),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'checkout') {
      await _deleteItem(item);
    } else if (action == 'open') {
      await _openItem(item);
    }
  }

  Future<void> _showMovedToOpenListSnackBar() async {
    final openList = await _findOpenList();
    if (!mounted) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: openList == null
              ? null
              : () {
                  scaffoldMessenger.hideCurrentSnackBar();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ItemListRoute(list: openList),
                    ),
                  );
                },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  openList == null
                      ? "Item moved to open list"
                      : "Item moved to open list. Tap to view",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (openList != null)
                const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Future<InventoryList?> _findOpenList() async {
    final lists = await _listService.all();
    return lists.firstWhereOrNull((list) => list.isOpenList);
  }

  bool _isExpired(Item item) {
    if (item.expirationDate == null) {
      return false;
    }
    return DateTime.tryParse(item.expirationDate!)?.isBefore(
          DateTime.now().subtract(const Duration(days: 1)),
        ) ??
        false;
  }

  String _formatOpenedSince(String? openedAt) {
    if (openedAt == null) {
      return "Not opened yet";
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

  String _expirationLabel(Item item) {
    if (item.expirationDate == null) {
      return "No Expiration Date";
    }
    return _isExpired(item)
        ? "Expired: ${item.expirationDate}"
        : "Expires: ${item.expirationDate}";
  }

  String _openedAtLabel(Item item) {
    if (item.openedAt == null) {
      return "Opened At: not set";
    }
    return "Opened At: ${item.openedAt}";
  }

  String _openedDaysCount(Item item) {
    if (item.openedAt == null) {
      return "";
    }
    final openedDate = DateTime.tryParse(item.openedAt!);
    if (openedDate == null) {
      return "";
    }
    final days = DateTime.now().difference(openedDate).inDays;
    return "$days d";
  }

  String _remainingDaysCount(Item item) {
    if (item.expirationDate == null) {
      return "";
    }
    final expirationDate = DateTime.tryParse(item.expirationDate!);
    if (expirationDate == null) {
      return "";
    }
    final days = expirationDate.difference(DateTime.now()).inDays;
    if (days >= 0) {
      return "$days d left";
    }
    return "${days.abs()} d ago";
  }

  Future<void> _viewProductDetails() async {
    try {
      Product product =
          (await _productService.search(widget.itemWrapper.productEan)).first;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductDetailRoute(product: product, list: widget.list),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Error loading product details"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.list.isOpenList ? "Opened Item Details" : "Item Details"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.itemWrapper.thumbUrl != null
                      ? InoventoryNetworkImage(
                          url: widget.itemWrapper.thumbUrl!)
                      : Icon(Icons.inventory_2_outlined,
                          size: 40,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.itemWrapper.displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text("EAN: ${widget.itemWrapper.productEan}",
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              onPressed: _viewProductDetails,
              icon: const Icon(Icons.info_outline),
              label: const Text("View Product Details"),
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                textStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer),
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          if (widget.list.isOpenList)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.45),
                child: ListTile(
                  leading: const Icon(Icons.lock_open),
                  title: Text(_formatOpenedSince(items.firstOrNull?.openedAt)),
                  subtitle:
                      const Text("Tap an item below to update the opened date"),
                ),
              ),
            ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Inventory Items (${items.length})",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isExpired = widget.list.isOpenList && _isExpired(item);
                final openItemForegroundColor = isExpired
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSurface;
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Column(
                    children: [
                      if (widget.list.isOpenList)
                        _DateDetailRow(
                          icon: Icons.lock_open,
                          iconColor: colorScheme.secondary,
                          label: _openedAtLabel(item),
                          valueHint: _openedDaysCount(item),
                          labelColor: openItemForegroundColor,
                          onTap: () => _editOpenedDate(item),
                        ),
                      if (widget.list.isOpenList) const Divider(height: 1),
                      Container(
                        color: isExpired ? colorScheme.errorContainer : null,
                        child: widget.list.isOpenList
                            ? _DateDetailRow(
                                icon: item.expirationDate != null
                                    ? Icons.event
                                    : Icons.event_available,
                                iconColor: item.expirationDate != null
                                    ? openItemForegroundColor
                                    : colorScheme.onSurfaceVariant,
                                label: _expirationLabel(item),
                                valueHint: _remainingDaysCount(item),
                                labelColor: openItemForegroundColor,
                                onTap: () => _editExpirationDate(item),
                              )
                            : ListTile(
                                leading: Icon(
                                  item.expirationDate != null
                                      ? Icons.event
                                      : Icons.event_available,
                                  color: item.expirationDate != null
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.grey,
                                ),
                                title: Text(_expirationLabel(item)),
                                subtitle:
                                    const Text("Tap to edit expiration date"),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color:
                                          Theme.of(context).colorScheme.error),
                                  onPressed: () => _handleItemRemoval(item),
                                ),
                                onTap: () => _editExpirationDate(item),
                              ),
                      ),
                      if (widget.list.isOpenList) const Divider(height: 1),
                      if (widget.list.isOpenList)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => _handleItemRemoval(item),
                            icon: Icon(
                              Icons.delete_outline,
                              color: openItemForegroundColor,
                            ),
                            label: Text(
                              "Remove",
                              style: TextStyle(
                                color: openItemForegroundColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              alignment: Alignment.centerLeft,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(16.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateDetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String valueHint;
  final Color? labelColor;
  final VoidCallback onTap;

  const _DateDetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.valueHint,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: labelColor,
                    ),
              ),
            ),
            if (valueHint.isNotEmpty)
              Text(
                valueHint,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
