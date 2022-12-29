import 'package:flutter/material.dart';

import '../../models/inventory_list_item.dart';

class ItemListWidget extends StatelessWidget {
  final List<InventoryListItem> items;
  final void Function(int listId, int itemId) onDelete;

  const ItemListWidget({Key? key, required this.items, required this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: ListTile.divideTiles(
            context: context,
            tiles: items.map((item) {
              return ListTile(
                title:
                    Text(item.productEan, style: const TextStyle(fontSize: 24)),
                trailing: PopupMenuButton<TextButton>(
                  itemBuilder: (BuildContext subContext) =>
                  <PopupMenuEntry<TextButton>>[
                    PopupMenuItem<TextButton>(
                        child: const Text("Delete"),
                        onTap: () => onDelete(item.listId, item.id)
                    )
                  ],
                ),
              );
            })).toList());
  }
}
