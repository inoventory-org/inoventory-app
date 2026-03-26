import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/item_list_route.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';

class MyInventoryListsWidget extends StatelessWidget {
  final List<InventoryList> lists;
  final Future<void> Function(int listId, BuildContext context) onDelete;
  final Future<void> Function(InventoryList list) onEdit;

  const MyInventoryListsWidget(
      {Key? key,
      required this.lists,
      required this.onDelete,
      required this.onEdit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: lists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final myList = lists[index];
        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onLongPress: () => onDelete(myList.id, context),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ItemListRoute(list: myList)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.inventory_2_outlined, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      myList.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    itemBuilder: (BuildContext subContext) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(value: "edit", child: Text("Edit")),
                      const PopupMenuItem<String>(value: "delete", child: Text("Delete")),
                    ],
                    onSelected: (String value) async {
                      switch (value) {
                        case "edit":
                          await onEdit(myList);
                          break;
                        case "delete":
                          await onDelete(myList.id, context);
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
