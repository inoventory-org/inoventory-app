import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/items/widgets/item_widget.dart';
import 'package:inoventory_ui/products/product_service.dart';

import '../../../config/injection.dart';

class InventoryListWidget extends StatefulWidget {
  final List<ItemWrapper> itemWrappers;
  final Future<bool> Function(ItemWrapper itemWrapper) onDelete;
  final Future<void> Function(ItemWrapper itemWrapper) onEdit;

  const InventoryListWidget(
      {Key? key,
      required this.itemWrappers,
      required this.onDelete,
      required this.onEdit})
      : super(key: key);

  @override
  State<InventoryListWidget> createState() => _InventoryListWidgetState();
}

class _InventoryListWidgetState extends State<InventoryListWidget> {
  final ProductService _productService = getIt<ProductService>();

  @override
  void initState() {
    super.initState();
    // force refetch for all products in list
    // widget.itemWrappers.forEach((itemWrapper) async { await _productService.search(itemWrapper.productEan, fresh: true); });
  }
  @override
  Widget build(BuildContext context) {
    return ListView(
        children: ListTile.divideTiles(
            context: context,
            tiles: widget.itemWrappers.map((itemWrapper) {
              return InventoryItemWidget(itemWrapper, widget.onDelete);
            })).toList());
  }
}
