import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list.dart';
import 'package:inoventory_ui/inventory/items/inventory_item_list_widget.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/routes/product_search_route.dart';
import 'package:inoventory_ui/inventory/items/inventory_list_widget.dart';
import 'package:inoventory_ui/ean/barcode_scanner.dart';
import 'package:inoventory_ui/shared/widgets/expandable_floating_action_button.dart';
import 'package:inoventory_ui/shared/widgets/future_error_retry_widget.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_appbar.dart';
import 'dart:developer' as developer;

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

  Future<void> onDelete(itemId) async {
    await itemService.delete(widget.list.id, itemId);
    await _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() {
      futureItems = itemService.all(widget.list.id);
    });
  }

  void transitToProductSearchPage(BuildContext context, String? initialSearchValue) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductSearchRoute(
                productService: productService,
                initialSearchValue: initialSearchValue,
                list: widget.list))
    ).whenComplete(_refreshList);
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
                developer.log("An error occurred while retrieving items.", error: snapshot.error);
                return FutureErrorRetryWidget(
                    onRetry: _refreshList,
                    child: const Center(child: Text('An error occurred while retrieving items. Please try again.')));
              }
              if (snapshot.hasData) {
                return InventoryListWidget(
                    itemWrappers: snapshot.data!, onDelete: onDelete, onEdit: onEdit);
              }
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      floatingActionButton: ExpandableFab(distance: 50, children: [
        ActionButton(
            icon: const Icon(Icons.camera_alt, color: Colors.black),
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
          icon: const Icon(Icons.edit, color: Colors.black),
          onPressed: () {
            transitToProductSearchPage(context, "3017620425035");
          },
        ),
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
