import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/ean/barcode_scan_route.dart';
import 'package:inoventory_ui/expiry_scan/expiry_date_picker.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:inoventory_ui/inventory/items/item_search_route.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/items/widgets/grouped_list_widget.dart';
import 'package:inoventory_ui/inventory/items/widgets/items_future_builder.dart';
import 'package:inoventory_ui/inventory/items/widgets/list_widget.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_service.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/routes/product_scan_route.dart';
import 'package:inoventory_ui/products/routes/product_search_route.dart';
import 'package:inoventory_ui/shared/models/sorting_options.dart';
import 'package:inoventory_ui/shared/widgets/expandable_floating_action_button.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_appbar.dart';

enum SORTING { dateAdded, name, expirationDate, quantity }

enum _RemovalAction { checkout, open }

class ItemListRoute extends StatefulWidget {
  final InventoryList list;
  final bool focusExpiring;

  const ItemListRoute(
      {super.key, required this.list, this.focusExpiring = false});

  @override
  State<ItemListRoute> createState() => _ItemListRouteState();
}

class _ItemListRouteState extends State<ItemListRoute> {
  final ProductService _productService = getIt<ProductService>();
  final ItemService _itemService = getIt<ItemService>();
  final InventoryListService _listService = getIt<InventoryListService>();
  final _storage = const FlutterSecureStorage();

  late Future<List<ItemWrapper>> futureItems;
  late List<ItemWrapper> itemWrappers;
  late Future<Map<String, List<ItemWrapper>>> futureGroupedItems;
  bool groupByCategory = false;
  SORTING _sortByKey = SORTING.dateAdded;
  bool _isAsc = false;
  bool _focusExpiring = false;
  int _itemCount = 0;

  @override
  void initState() {
    super.initState();
    // Apply notification-driven focus immediately for a snappy UI, before prefs load.
    if (widget.focusExpiring) {
      _focusExpiring = true;
      _sortByKey = SORTING.expirationDate;
      _isAsc = true;
    }
    futureGroupedItems = _loadGroupedItems();
    futureItems = _loadItems();
    // Always load the stored preference — never save from here.
    // Opening via a notification must not permanently override the user's setting.
    _loadFocusPreference();
  }

  Future<List<ItemWrapper>> _loadItems() async {
    final wrappers = await _itemService.all(widget.list.id);
    final count =
        wrappers.fold<int>(0, (sum, wrapper) => sum + wrapper.items.length);
    if (mounted && _itemCount != count) {
      setState(() {
        _itemCount = count;
      });
    } else {
      _itemCount = count;
    }
    return wrappers;
  }

  Future<Map<String, List<ItemWrapper>>> _loadGroupedItems() async {
    final groupedItems =
        await _itemService.allGroupedBy(widget.list.id, "category");
    final count = groupedItems.values
        .expand((wrappers) => wrappers)
        .fold<int>(0, (sum, wrapper) => sum + wrapper.items.length);
    if (mounted && _itemCount != count) {
      setState(() {
        _itemCount = count;
      });
    } else {
      _itemCount = count;
    }
    return groupedItems;
  }

  Future<void> _loadFocusPreference() async {
    final value =
        await _storage.read(key: "list_${widget.list.id}_focusExpiring");
    if (!mounted) return;
    final storedFocus = value == 'true';
    // Merge: show focus expiring if the user has it stored OR this session was
    // triggered by a notification. Stored preference is never written here.
    final sessionFocus = storedFocus || widget.focusExpiring;
    setState(() {
      _focusExpiring = sessionFocus;
      if (sessionFocus) {
        _sortByKey = SORTING.expirationDate;
        _isAsc = true;
      }
    });
  }

  Future<void> _saveFocusPreference(bool value) async {
    await _storage.write(
        key: "list_${widget.list.id}_focusExpiring", value: value.toString());
  }

  void _toggleFocusExpiring() {
    setState(() {
      _focusExpiring = !_focusExpiring;
      if (_focusExpiring) {
        _sortByKey = SORTING.expirationDate;
        _isAsc = true;
      } else {
        _sortByKey = SORTING.dateAdded;
        _isAsc = false;
      }
    });
    _saveFocusPreference(_focusExpiring);
  }

  Future<void> onEdit(ItemWrapper itemWrapper) async {
    await _refreshList();
  }

  Future<bool> onDelete(ItemWrapper itemWrapper) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final item = await _getItemToRemove(itemWrapper);
    if (item == null) {
      return false;
    }

    try {
      if (widget.list.isOpenList) {
        await _itemService.delete(widget.list.id, item.id);
        scaffoldMessenger.showSnackBar(
          _getSnackBar("Removed opened item", Colors.green),
        );
      } else {
        final action = await _chooseRemovalAction(itemWrapper);
        if (action == null) {
          return false;
        }

        if (action == _RemovalAction.checkout) {
          await _itemService.delete(widget.list.id, item.id);
          scaffoldMessenger.showSnackBar(
            _getSnackBar("Successfully deleted item", Colors.green,
                withUndo: true),
          );
        } else {
          final expirationDate =
              item.expirationDate ?? await _pickRequiredExpirationDate();
          if (expirationDate == null) {
            return false;
          }
          await _itemService.open(widget.list.id, item.id,
              expirationDate: expirationDate);
          await _showMovedToOpenListSnackBar(scaffoldMessenger);
        }
      }
    } catch (e) {
      scaffoldMessenger
          .showSnackBar(_getSnackBar("Error deleting item: ", Colors.red));

      developer.log("Could not delete item", error: e);

      return false;
    }

    await _refreshList();
    return true;
  }

  Future<_RemovalAction?> _chooseRemovalAction(ItemWrapper itemWrapper) {
    return showModalBottomSheet<_RemovalAction>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "What do you want to do with ${itemWrapper.displayName}?",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _RemovalAction.open),
                  icon: const Icon(Icons.lock_open),
                  label: const Text("Open Item"),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, _RemovalAction.checkout),
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
        );
      },
    );
  }

  Future<String?> _pickRequiredExpirationDate() async {
    return pickExpiryDate(
      context,
      initialDate: DateTime.now(),
      helpText: "Select an expiration date for the opened item",
      scanTitle: 'Scan Expiry Date',
      confirmationMode: ExpiryDateConfirmationMode.requireConfirmation,
    );
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

  Future<void> _showMovedToOpenListSnackBar(
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    final openList = await _findOpenList();
    if (!mounted) {
      return;
    }

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
                      ? "Moved item to open list"
                      : "Moved item to open list. Tap to view",
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

  Future<void> onEanDeleteScan(String ean) async {
    futureItems.then((value) async {
      ItemWrapper? result =
          value.firstWhereOrNull((element) => element.productEan == ean);
      if (result == null) {
        return;
      }

      await onDelete(result);
    });
  }

  Future<Item?> _getItemToRemove(ItemWrapper itemWrapper) async {
    if (itemWrapper.items.map((e) => e.expirationDate).toSet().length == 1) {
      return itemWrapper.items.first;
    }

    return await showDialog<Item>(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: const Text("Choose item"),
              scrollable: true,
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("Which item do you want to remove?"),
                ...itemWrapper.items.map((e) => TextButton(
                      onPressed: () => Navigator.pop(context, e),
                      child: Text(e.expirationDate ?? "<no expiration date>"),
                    )),
                OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"))
              ]));
        });
  }

  Future<void> _refreshList() async {
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        if (groupByCategory) {
          futureGroupedItems = _loadGroupedItems();
        } else {
          futureItems = _loadItems();
        }
      });
    });
  }

  void transitToProductSearchPage(
      BuildContext context, String? initialSearchValue) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductSearchRoute(
                productService: _productService,
                initialSearchValue: initialSearchValue,
                list: widget.list))).whenComplete(_refreshList);
  }

  void transitToItemSearchPage(
      BuildContext context, String? initialSearchValue) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ItemSearchRoute(
                itemWrappers: itemWrappers,
                onDelete: onDelete,
                onEdit: onEdit)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildInoventoryAppBar(),
      body: RefreshIndicator(
          onRefresh: _refreshList,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: groupByCategory
              ? ItemsFutureBuilder<Map<String, List<ItemWrapper>>>(
                  futureGroupedItems, _refreshList, (context, snapshot) {
                  final groupedItems = snapshot.data!;
                  return GroupedInventoryListWidget(
                      groupedItems, onDelete, onEdit);
                })
              : ItemsFutureBuilder<List<ItemWrapper>>(futureItems, _refreshList,
                  (context, snapshot) {
                  sortItemsByKey(snapshot, _sortByKey, _isAsc);
                  itemWrappers = snapshot.data!;
                  return InventoryListWidget(
                    itemWrappers: snapshot.data!,
                    onDelete: onDelete,
                    onEdit: onEdit,
                    focusExpiring: _focusExpiring,
                    isOpenList: widget.list.isOpenList,
                  );
                })),
      floatingActionButton: buildFloatingActionButton(context),
    );
  }

  InoventoryAppBar buildInoventoryAppBar() {
    return InoventoryAppBar(
      title: widget.list.name,
      subtitle: "$_itemCount ${_itemCount == 1 ? 'item' : 'items'}",
      isFocusExpiring: _focusExpiring,
      onFocusExpiringToggled: _toggleFocusExpiring,
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
            navigator
                .push(MaterialPageRoute(
                    builder: (context) =>
                        ProductScanRoute(inventoryList: widget.list)))
                .whenComplete((_refreshList));
          }),
      ActionButton(
          icon: const Icon(Icons.search_off_outlined, color: Colors.black),
          onPressed: () async {
            final navigator = Navigator.of(context);
            navigator
                .push(MaterialPageRoute(
                    builder: (context) => ProductSearchRoute(
                        productService: _productService, list: widget.list)))
                .whenComplete((_refreshList));
          }),
      // delete scan button
      ActionButton(
          icon: const Icon(Icons.delete, color: Colors.black),
          onPressed: () async {
            final navigator = Navigator.of(context);
            final barcodeScanResult = await navigator.push<String>(
              MaterialPageRoute(builder: (context) => const BarcodeScanRoute()),
            );
            if (barcodeScanResult == null || barcodeScanResult.isEmpty) {
              return;
            }
            await onEanDeleteScan(barcodeScanResult);
          }),
    ]);
  }

  void sortItemsByKey(AsyncSnapshot<List<ItemWrapper>> snapshot,
      SORTING sortByKey, bool isAsc) {
    int direction = isAsc ? 1 : -1;
    snapshot.data?.sort((wrapper1, wrapper2) {
      switch (sortByKey) {
        case SORTING.dateAdded:
          final id1 =
              wrapper1.items.map((e) => e.id).reduce((a, b) => a < b ? a : b);
          final id2 =
              wrapper2.items.map((e) => e.id).reduce((a, b) => a < b ? a : b);
          return direction * id1.compareTo(id2);
        case SORTING.name:
          return direction *
              wrapper1.displayName.compareTo(wrapper2.displayName);
        case SORTING.expirationDate:
          return compareByExpirationDates(wrapper1, wrapper2, isAsc);
        case SORTING.quantity:
          return direction *
              wrapper1.items.length.compareTo(wrapper2.items.length);
      }
    });
  }

  int compareByExpirationDates(
      ItemWrapper wrapper1, ItemWrapper wrapper2, bool isAsc) {
    int direction = isAsc ? 1 : -1;
    DateTime defaultDate =
        isAsc ? DateTime.parse("9999-01-01") : DateTime.parse("1970-01-01");
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
