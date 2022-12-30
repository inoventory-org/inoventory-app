import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/routes/list/inventory_list_detail_route.dart';


class MyInventoryListsWidget extends StatelessWidget {
  final List<InventoryList> lists;
  final Future<void> Function(int listId, BuildContext context) deleteList;

  const MyInventoryListsWidget({Key? key, required this.lists, required this.deleteList})
      : super(key: key);


  @override
  Widget build(BuildContext context) {
    return ListView(
        children: ListTile.divideTiles(
            context: context,
            tiles: lists.map((myList) {
              return ListTile(
                onLongPress: () => deleteList(myList.id, context),
                title: Text(myList.name, style: const TextStyle(fontSize: 24)),
                trailing: PopupMenuButton<TextButton>(
                  itemBuilder: (BuildContext subContext) =>
                      <PopupMenuEntry<TextButton>>[
                    PopupMenuItem<TextButton>(
                        child: const Text("Delete"),
                        onTap: () => deleteList(myList.id, context)
                    )
                  ],
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              InventoryListDetailRoute(list: myList)));
                },
              );
            })).toList());
  }
}
