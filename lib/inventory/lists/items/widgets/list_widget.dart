import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/lists/models/item_wrapper.dart';

import 'item_widget.dart';

class InventoryListWidget extends StatelessWidget {
  final List<ItemWrapper> itemWrappers;

  const InventoryListWidget(
      {Key? key,
      required this.itemWrappers})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: ListTile.divideTiles(
            context: context,
            tiles: itemWrappers.map((itemWrapper) {
              return InventoryItemWidget(itemWrapper);
            })).toList());
  }
}
