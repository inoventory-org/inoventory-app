import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/services/inventory_list_service.dart';
import 'package:inoventory_ui/views/list/inventory_list_detail_view.dart';
import 'package:inoventory_ui/widgets/ConfirmationModal.dart';

class ListsWidget extends StatelessWidget {
  final List<InventoryList> lists;
  final InventoryListService listService;

  const ListsWidget({Key? key, required this.lists, required this.listService})
      : super(key: key);

  Future deleteList(int listId, BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return ConfirmationModal(
              title: "Delete List?",
              message:
              "Are you sure you want to delete the list?",
              onConfirm: () async {
                await listService.delete(listId);
              });
        });
  }

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
                              InventoryListDetailWidget(list: myList)));
                },
              );
            })).toList());
  }
}
