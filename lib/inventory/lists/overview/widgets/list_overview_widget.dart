import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/lists/items/item_list_route.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';

class ListOverviewWidget extends StatelessWidget {
  final List<InventoryList> lists;
  final Future<void> Function(int listId, BuildContext context) onDelete;
  final Future<void> Function(InventoryList list) onEdit;

  const ListOverviewWidget(
      {Key? key,
      required this.lists,
      required this.onDelete,
      required this.onEdit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: ListTile.divideTiles(
            context: context,
            tiles: lists.map((myList) {
              return ListTile(
                onLongPress: () => onDelete(myList.id, context),
                title: Text(myList.name, style: const TextStyle(fontSize: 24)),
                trailing: PopupMenuButton<String>(
                    itemBuilder: (BuildContext subContext) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                              value: "edit", child: Text("Edit")),
                          const PopupMenuItem<String>(
                              value: "delete", child: Text("Delete")),
                        ],
                    onSelected: (String value) async {
                      switch (value) {
                        case "edit":
                          await onEdit(myList);
                          break;
                        case "delete":
                          await onDelete(myList.id, context);
                          break;
                        default:
                          break;
                      }
                      if (value == "delete") {}
                    }),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: const RouteSettings(name: "/list-view"),
                          builder: (context) => ItemListRoute(list: myList)));
                },
              );
            })).toList());
  }
}
