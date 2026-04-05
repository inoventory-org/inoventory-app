import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
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
            const SnackBar(content: Text("Item deleted"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting item: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editExpirationDate(Item item) async {
    DateTime? initialDate = item.expirationDate != null ? DateTime.tryParse(item.expirationDate!) : null;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      String newDateOptions = "${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      if (newDateOptions != item.expirationDate) {
        try {
          // Send updated values back so itemService recognizes them
          Item updatedItem = Item(
            item.id,
            item.listId,
            item.productEan,
            item.displayName,
            expirationDate: newDateOptions,
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
              const SnackBar(content: Text("Expiration date updated"), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error updating expiration date: $e"), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  Future<void> _viewProductDetails() async {
    try {
      Product product = (await _productService.search(widget.itemWrapper.productEan)).first;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailRoute(product: product, list: widget.list),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error loading product details"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Item Details"),
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.itemWrapper.thumbUrl != null
                      ? InoventoryNetworkImage(url: widget.itemWrapper.thumbUrl!)
                      : Icon(Icons.inventory_2_outlined, size: 40, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.itemWrapper.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text("EAN: ${widget.itemWrapper.productEan}", style: Theme.of(context).textTheme.bodyMedium),
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
                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Inventory Items (${items.length})",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: ListTile(
                    leading: Icon(
                        item.expirationDate != null ? Icons.event : Icons.event_available,
                        color: item.expirationDate != null ? Theme.of(context).colorScheme.primary : Colors.grey),
                    title: Text(item.expirationDate != null ? "Expires: ${item.expirationDate}" : "No Expiration Date"),
                    subtitle: const Text("Tap to edit expiration date"),
                    onTap: () => _editExpirationDate(item),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                      onPressed: () => _deleteItem(item),
                    ),
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
