import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/ean/barcode_scanner.dart';
import 'package:inoventory_ui/inventory/items/item_search_route.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/items/widgets/grouped_list_widget.dart';
import 'package:inoventory_ui/inventory/items/widgets/items_future_builder.dart';
import 'package:inoventory_ui/inventory/items/widgets/list_widget.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/routes/product_scan_route.dart';
import 'package:inoventory_ui/products/routes/product_search_route.dart';
import 'package:inoventory_ui/shared/models/sorting_options.dart';
import 'package:inoventory_ui/shared/widgets/expandable_floating_action_button.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_appbar.dart';

enum SORTING { dateAdded, name, expirationDate, quantity }

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
  late List<ItemWrapper> itemWrappers;
  late Future<Map<String, List<ItemWrapper>>> futureGroupedItems;
  bool groupByCategory = false;
  SORTING _sortByKey = SORTING.dateAdded;
  bool _isAsc = false;

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

      scaffoldMessenger.showSnackBar(_getSnackBar("Successfully deleted item", Colors.green, withUndo: true));
    } catch (e) {
      scaffoldMessenger.showSnackBar(_getSnackBar("Error deleting item: ", Colors.red));

      developer.log("Could not delete item", error: e);

      return false;
    }

    await _refreshList();
    return true;
  }

  SnackBar _getSnackBar(String text, Color color, {bool withUndo = false}) {
    TextStyle style = const TextStyle(color: Colors.white);
    return SnackBar(
        content: Text(text, style: style),
        backgroundColor: color,
        showCloseIcon: true,
        duration: Duration(seconds: withUndo ? 6 : 4),
        action: withUndo
            ? SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await _itemService.undoDeletion();
                  await _refreshList();
                },
              )
            : null);
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
                ...itemWrapper.items.map((e) => TextButton(
                      onPressed: () => Navigator.pop(context, e.id),
                      child: Text(e.expirationDate ?? "<no expiration date>"),
                    )),
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

  void transitToItemSearchPage(BuildContext context, String? initialSearchValue) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ItemSearchRoute(itemWrappers: itemWrappers, onDelete: onDelete, onEdit: onEdit)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildInoventoryAppBar(),
      body: RefreshIndicator(
          onRefresh: _refreshList,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: groupByCategory
              ? ItemsFutureBuilder<Map<String, List<ItemWrapper>>>(futureGroupedItems, _refreshList, (context, snapshot) {
                  return GroupedInventoryListWidget(snapshot.data!, onDelete, onEdit);
                })
              : ItemsFutureBuilder<List<ItemWrapper>>(futureItems, _refreshList, (context, snapshot) {
                  sortItemsByKey(snapshot, _sortByKey, _isAsc);
                  itemWrappers = snapshot.data!;
                  return InventoryListWidget(itemWrappers: snapshot.data!, onDelete: onDelete, onEdit: onEdit);
                })),
      floatingActionButton: buildFloatingActionButton(context),
    );
  }

  InoventoryAppBar buildInoventoryAppBar() {
    return InoventoryAppBar(
      title: widget.list.name,
      onSearchButtonPressed: () {
        transitToItemSearchPage(context, "");
      },
      onGroupButtonPressed: () {
        setState(() {
          groupByCategory = !groupByCategory;
        });
      },
      sortingOptions: SortingOptions(
          sortOptions: SORTING.values,
          onSortingDirectionChange: () {
            setState(() {
              _isAsc = !_isAsc;
            });
          },
          onSortingKeySelected: (key) => {
                setState(() {
                  _sortByKey = key;
                })
              }),
    );
  }

  ExpandableFab buildFloatingActionButton(BuildContext context) {
    return ExpandableFab(iconData: Icons.camera_alt, distance: 70, children: [
      ActionButton(
          icon: const Icon(Icons.camera_alt, color: Colors.black),
          onPressed: () async {
            final navigator = Navigator.of(context);
            navigator.push(MaterialPageRoute(builder: (context) => ProductScanRoute(inventoryList: widget.list))).whenComplete((_refreshList));
          }),
      ActionButton(
          icon: const Icon(Icons.search_off_outlined, color: Colors.black),
          onPressed: () async {
            final navigator = Navigator.of(context);
            navigator.push(MaterialPageRoute(builder: (context) => ProductSearchRoute(productService: _productService, list: widget.list))).whenComplete((_refreshList));
          }),
      // delete scan button
      ActionButton(
          icon: const Icon(Icons.delete, color: Colors.black),
          onPressed: () async {
            var barcodeScanResult = await _barcodeScanner.scanBarcodeNormal();
            await onEanDeleteScan(barcodeScanResult);
          }),
    ]);
  }

  void sortItemsByKey(AsyncSnapshot<List<ItemWrapper>> snapshot, SORTING sortByKey, bool isAsc) {
    int direction = isAsc ? 1 : -1;
    snapshot.data?.sort((wrapper1, wrapper2) {
      switch (sortByKey) {
        case SORTING.name:
          return direction * wrapper1.displayName.compareTo(wrapper2.displayName);
        case SORTING.expirationDate:
          return compareByExpirationDates(wrapper1, wrapper2, isAsc);
        case SORTING.quantity:
          return direction * wrapper1.items.length.compareTo(wrapper2.items.length);
        default:
          return 0; // Default return value
      }
    });
  }

  int compareByExpirationDates(ItemWrapper wrapper1, ItemWrapper wrapper2, bool isAsc) {
    int direction = isAsc ? 1 : -1;
    DateTime defaultDate = isAsc ? DateTime.parse("9999-01-01") : DateTime.parse("1970-01-01");
    List<DateTime> firstDates = wrapper1.items //
        .where((item) => item.expirationDate != null) //
        .map((item) => DateTime.parse(item.expirationDate!)) //
        .sorted();
    List<DateTime> secondDates = wrapper2.items //
        .where((item) => item.expirationDate != null) //
        .map((item) => DateTime.parse(item.expirationDate!)) //
        .sorted();

    if (!isAsc) {
      firstDates = firstDates.reversed.toList();
      secondDates = secondDates.reversed.toList();
    }

    DateTime firstCandidate = firstDates.firstOrNull ?? defaultDate;
    DateTime secondCandidate = secondDates.firstOrNull ?? defaultDate;
    return direction * firstCandidate.compareTo(secondCandidate);
  }
}
