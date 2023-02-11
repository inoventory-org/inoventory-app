import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/ean/barcode_scanner.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/items/widgets/grouped_list_widget.dart';
import 'package:inoventory_ui/inventory/items/widgets/items_future_builder.dart';
import 'package:inoventory_ui/inventory/items/widgets/list_widget.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/routes/product_scan_route.dart';
import 'package:inoventory_ui/products/routes/product_search_route.dart';
import 'package:inoventory_ui/shared/widgets/expandable_floating_action_button.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_appbar.dart';

class ItemListRoute extends StatefulWidget {
  final InventoryList list;

  const ItemListRoute({super.key, required this.list});

  @override
  State<ItemListRoute> createState() => _ItemListRouteState();
}

class _ItemListRouteState extends State<ItemListRoute> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final ProductService _productService = getIt<ProductService>();
  final ItemService _itemService = getIt<ItemService>();
  late Future<List<ItemWrapper>> futureItems;
  late Future<Map<String, List<ItemWrapper>>> futureGroupedItems;
  bool groupByCategory = false;


  @override
  void initState() {
    super.initState();
      futureGroupedItems = _itemService.allGroupedBy(widget.list.id, "category");
      futureItems = _itemService.all(widget.list.id);
  }

  Future<void> onEdit(ItemWrapper itemWrapper) async {
    await _refreshList();
  }

  Future<bool> onDelete(ItemWrapper itemWrapper) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final int? itemId = await getItemIdToDelete(itemWrapper);
    if (itemId == null) {
      return false;
    }

    try {
      await _itemService.delete(widget.list.id, itemId);

      scaffoldMessenger.showSnackBar(_getSnackBar("Successfully deleted item", Colors.green));
    } catch (e) {
      scaffoldMessenger.showSnackBar(_getSnackBar("Error deleting item: ", Colors.red));

      developer.log("Could not delete item", error: e);

      return false;
    }

    await _refreshList();
    return true;
  }

  SnackBar _getSnackBar(String text, Color color) {
    TextStyle style = const TextStyle(color: Colors.white);
    return SnackBar(content: Text(text, style: style), backgroundColor: color);
  }

  Future<void> onEanDeleteScan(String ean) async {
    futureItems.then((value) async {
      ItemWrapper? result = value.firstWhereOrNull((element) => element.productEan == ean);
      if (result == null) {
        return;
      }

      await onDelete(result);
    });
  }

  Future<int?> getItemIdToDelete(ItemWrapper itemWrapper) async {
    if (itemWrapper.items.map((e) => e.expirationDate).toSet().length == 1) {
      return itemWrapper.items.first.id;
    }

    return await showDialog<int>(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: const Text("Choose item"),
              scrollable: true,
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("Which item do you want to remove?"),
                ...itemWrapper.items
                    .map((e) => TextButton(
                          onPressed: () => Navigator.pop(context, e.id),
                          child: Text(e.expirationDate ?? "<no expiration date>"),
                        ))
                    .toList(),
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel"))
              ]));
        });
  }

  Future<void> _refreshList() async {
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        if (groupByCategory) {
          futureGroupedItems = _itemService.allGroupedBy(widget.list.id, "category");
        } else {
          futureItems = _itemService.all(widget.list.id);
        }
      });
    });
  }

  void transitToProductSearchPage(BuildContext context, String? initialSearchValue) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProductSearchRoute(productService: _productService, initialSearchValue: initialSearchValue, list: widget.list)))
        .whenComplete(_refreshList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: InoventoryAppBar(
        title: widget.list.name,
        onPressedCallback: () {
          setState(() {
            groupByCategory = !groupByCategory;
          });
        },
      ),
      body: RefreshIndicator(
          onRefresh: _refreshList,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: groupByCategory
              ? ItemsFutureBuilder<Map<String, List<ItemWrapper>>>(futureGroupedItems, _refreshList, (context, snapshot) {
                  return GroupedInventoryListWidget(snapshot.data!, onDelete, onEdit);
                })
              : ItemsFutureBuilder<List<ItemWrapper>>(futureItems, _refreshList, (context, snapshot)  {
                  return InventoryListWidget(itemWrappers: snapshot.data!, onDelete: onDelete, onEdit: onEdit);
                })),
      floatingActionButton: ExpandableFab(iconData: Icons.camera_alt, distance: 50, children: [
        ActionButton(
            icon: const Icon(Icons.add_outlined, color: Colors.black),
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.push(MaterialPageRoute(builder: (context) => ProductScanRoute(inventoryList: widget.list))).whenComplete((_refreshList));
            }),
        // delete scan button
        ActionButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            onPressed: () async {
              var barcodeScanResult = await _barcodeScanner.scanBarcodeNormal();
              await onEanDeleteScan(barcodeScanResult);
            }),
      ]),
    );
  }
}

// child: FutureBuilder<List<ItemWrapper>>(
// future: futureItems,
// builder: (context, snapshot) {
// if (snapshot.connectionState == ConnectionState.done) {
// if (snapshot.hasError) {
// developer.log("An error occurred while retrieving items.",
// error: snapshot.error);
// return FutureErrorRetryWidget(
// onRetry: _refreshList,
// child: const Center(
// child: Text(
// 'An error occurred while retrieving items. Please try again.')));
// }
// if (snapshot.hasData) {
// return InventoryListWidget(
// itemWrappers: snapshot.data!,
// onDelete: onDelete,
// onEdit: onEdit);
// }
// }
// return const Center(child: CircularProgressIndicator());
// },
// ),
