import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/services/inventory_list_service.dart';

import 'inventory_list_detail_view.dart';

class InventoryListWidget extends StatefulWidget {
  const InventoryListWidget({Key? key}) : super(key: key);

  @override
  State<InventoryListWidget> createState() => _InventoryListWidgetState();
}

class _InventoryListWidgetState extends State<InventoryListWidget> {
  final inventoryListService = InventoryListService();
  late final List<InventoryList> _inventoryLists;

  @override
  void initState() {
    super.initState();
    _inventoryLists = inventoryListService.all();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: ListTile.divideTiles(
          context: context,
          tiles: _inventoryLists.map((e) {
            return ListTile(
              title: Text(e.name, style: const TextStyle(fontSize: 24)),
              trailing: const Icon(Icons.more_vert),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            InventoryListDetailWidget(list: e)));
              },
            );
          })).toList(),
    );
  }
}
