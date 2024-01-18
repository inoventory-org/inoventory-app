import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/items/widgets/item_widget.dart';
import 'package:uuid/uuid.dart';

final PageStorageBucket pageBucket = PageStorageBucket();

class InventoryListWidget extends StatefulWidget {
  final List<ItemWrapper> itemWrappers;
  final Future<bool> Function(ItemWrapper itemWrapper)? onDelete;
  final Future<void> Function(ItemWrapper itemWrapper)? onEdit;

  const InventoryListWidget({super.key, required this.itemWrappers, this.onDelete, this.onEdit});

  @override
  State<InventoryListWidget> createState() => _InventoryListWidgetState();
}

class _InventoryListWidgetState extends State<InventoryListWidget> {
  final Uuid uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    // force refetch for all products in list
    // widget.itemWrappers.forEach((itemWrapper) async { await _productService.search(itemWrapper.productEan, fresh: true); });
  }

  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: pageBucket,
      child: ListView(
          key: PageStorageKey<String>(
              widget.itemWrappers.isNotEmpty ? "inoventoryList-${widget.itemWrappers.first.listId}" : "inoventoryList-${uuid.v4().toString().substring(0, 8)}"),
          padding: const EdgeInsets.only(bottom: 60.0),
          children: ListTile.divideTiles(
              context: context,
              tiles: widget.itemWrappers.map((itemWrapper) {
                return InventoryItemWidget(itemWrapper, widget.onDelete);
              })).toList()),
    );
  }
}
