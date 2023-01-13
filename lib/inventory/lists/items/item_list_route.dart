import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/ean/barcode_scanner.dart';
import 'package:inoventory_ui/inventory/lists/items/item_list_controller.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/inventory/lists/models/item_wrapper.dart';
import 'package:inoventory_ui/products/routes/product_search_route.dart';
import 'package:inoventory_ui/shared/widgets/expandable_floating_action_button.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_appbar.dart';

import 'widgets/list_widget.dart';

class ItemListRoute extends StatefulWidget {
  final InventoryList list;

  const ItemListRoute({super.key, required this.list});

  @override
  State<ItemListRoute> createState() => _ItemListRouteState();
}

class _ItemListRouteState extends State<ItemListRoute> {
  final _barcodeScanner = getIt<BarcodeScanner>();
  late final ItemListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ItemListController>(param1: widget.list);
    _controller.initialize();
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
      //await _itemService.delete(widget.list.id, itemId);

      scaffoldMessenger.showSnackBar(
          _getSnackBar("Successfully deleted item", Colors.green));
    } catch (e) {
      scaffoldMessenger
          .showSnackBar(_getSnackBar("Error deleting item: ", Colors.red));

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
    // futureItems.then((value) async {
    //   ItemWrapper? result =
    //       value.firstWhereOrNull((element) => element.productEan == ean);
    //   if (result == null) {
    //     return;
    //   }
    //
    //   await onDelete(result);
    // });
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
                          child:
                              Text(e.expirationDate ?? "<no expiration date>"),
                        ))
                    .toList(),
                OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"))
              ]));
        });
  }

  Future<void> _refreshList() async {
    // setState(() {
    //   futureItems = _itemService.all(widget.list.id);
    // });
  }

  void transitToProductSearchPage(
      BuildContext context, String? initialSearchValue) {
    // Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //         builder: (context) => ProductSearchRoute(
    //             productService: _productService,
    //             initialSearchValue: initialSearchValue,
    //             list: widget.list))).whenComplete(_refreshList);
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
        child: ValueListenableBuilder<InventoryList>(
          valueListenable: _controller.listNotifier,
          builder: (context, list, _) {
            return InventoryListWidget(itemWrappers: list.items);
            // if (snapshot.connectionState == ConnectionState.done) {
            //   if (snapshot.hasError) {
            //     developer.log("An error occurred while retrieving items.",
            //         error: snapshot.error);
            //     return FutureErrorRetryWidget(
            //         onRetry: _refreshList,
            //         child: const Center(
            //             child: Text(
            //                 'An error occurred while retrieving items. Please try again.')));
            //   }
            //   if (snapshot.hasData) {
            //     return InventoryListWidget(
            //         itemWrappers: snapshot.data!,
            //         onDelete: onDelete,
            //         onEdit: onEdit);
            //   }
            // }
            // return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      floatingActionButton:
          ExpandableFab(iconData: Icons.camera_alt, distance: 50, children: [
        ActionButton(
            icon: const Icon(Icons.add_outlined, color: Colors.black),
            onPressed: () async {
              final navigator = Navigator.of(context);
              var barcodeScanResult = await _barcodeScanner.scanBarcodeNormal();
              navigator.push(MaterialPageRoute(
                  builder: (context) => ProductSearchRoute(
                      initialSearchValue: barcodeScanResult,
                      list: widget.list)));
            }),
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
