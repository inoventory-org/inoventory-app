import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/ean/barcode_scanner.dart';
import 'package:inoventory_ui/inventory/items/inventory_item.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/items/widgets/inventory_list_widget.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/routes/product_search_route.dart';
import 'package:inoventory_ui/shared/widgets/expandable_floating_action_button.dart';
import 'package:inoventory_ui/shared/widgets/future_error_retry_widget.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_appbar.dart';

class InventoryListDetailRoute extends StatefulWidget {
  final InventoryList list;

  const InventoryListDetailRoute({super.key, required this.list});

  @override
  State<InventoryListDetailRoute> createState() =>
      _InventoryListDetailRouteState();
}

class _InventoryListDetailRouteState extends State<InventoryListDetailRoute> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final ProductService productService = Dependencies.productService;
  final ItemService itemService = Dependencies.itemService;

  String barcodeScanResult = "";

  late Future<List<InventoryListItemWrapper>> futureItems;

  @override
  void initState() {
    super.initState();
    futureItems = itemService.all(widget.list.id);
  }

  void barcodeScanned(String barcode) {
    setState(() {
      barcodeScanResult = barcode;
    });
  }

  Future<void> onEdit(InventoryListItemWrapper itemWrapper) async {
    await _refreshList();
  }

  Future<void> onDelete(InventoryListItemWrapper itemWrapper) async {
    final int? itemId = await getItemIdToDelete(itemWrapper);
    if (itemId == null) {
      return;
    }

    await itemService.delete(widget.list.id, itemId);
    await _refreshList();
  }

  Future<void> onEanDeleteScan(String ean) async {
    futureItems.then((value) async {
      InventoryListItemWrapper? result =
          value.firstWhereOrNull((element) => element.productEan == ean);
      if (result == null) {
        return;
      }

      await onDelete(result);
    });
  }

  Future<int?> getItemIdToDelete(InventoryListItemWrapper itemWrapper) async {
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

  Future<void> _refreshList() async {
    setState(() {
      futureItems = itemService.all(widget.list.id);
    });
  }

  void transitToProductSearchPage(
      BuildContext context, String? initialSearchValue) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductSearchRoute(
                productService: productService,
                initialSearchValue: initialSearchValue,
                list: widget.list))).whenComplete(_refreshList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: InoventoryAppBar(
        title: widget.list.name,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: FutureBuilder<List<InventoryListItemWrapper>>(
          future: futureItems,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                developer.log("An error occurred while retrieving items.",
                    error: snapshot.error);
                return FutureErrorRetryWidget(
                    onRetry: _refreshList,
                    child: const Center(
                        child: Text(
                            'An error occurred while retrieving items. Please try again.')));
              }
              if (snapshot.hasData) {
                return InventoryListWidget(
                    itemWrappers: snapshot.data!,
                    onDelete: onDelete,
                    onEdit: onEdit);
              }
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      floatingActionButton:
          ExpandableFab(iconData: Icons.camera_alt, distance: 50, children: [
        ActionButton(
            icon: const Icon(Icons.add_outlined, color: Colors.black),
            onPressed: () async {
              final navigator = Navigator.of(context);
              barcodeScanResult = await _barcodeScanner.scanBarcodeNormal();
              navigator
                  .push(MaterialPageRoute(
                      builder: (context) => ProductSearchRoute(
                          initialSearchValue: barcodeScanResult,
                          productService: productService,
                          list: widget.list)))
                  .whenComplete((_refreshList));
            }),
        ActionButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            onPressed: () async {
              barcodeScanResult = await _barcodeScanner.scanBarcodeNormal();
              await onEanDeleteScan(barcodeScanResult);
            }),
      ]),
    );
  }
}

//
//       MyFutureBuilder<List<InventoryListItemWrapper>>(
//         future: futureItems,
//         futureFetcher: () {
//           return itemService.all(widget.list.id);
//         },
//         successBuilder: (context, snapshot) {
//           return ItemListWidget(items: snapshot.data ?? [], onDelete: deleteItem);
//         },
//       ),
