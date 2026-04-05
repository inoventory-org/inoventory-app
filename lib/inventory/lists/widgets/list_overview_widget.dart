import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/item_list_route.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';

class MyInventoryListsWidget extends StatelessWidget {
  final List<InventoryList> lists;
  final Future<void> Function(int listId, BuildContext context) onDelete;
  final Future<void> Function(InventoryList list) onEdit;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;

  const MyInventoryListsWidget(
      {Key? key,
      required this.lists,
      required this.onDelete,
      required this.onEdit,
      required this.onReorder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: lists.length,
      onReorder: (oldIndex, newIndex) async {
        await onReorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final myList = lists[index];
        final isOpenList = myList.isOpenList;
        return Padding(
            key: ValueKey("list-${myList.id}"),
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: isOpenList
                  ? Theme.of(context)
                      .colorScheme
                      .tertiaryContainer
                      .withOpacity(0.35)
                  : null,
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ItemListRoute(list: myList)),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isOpenList
                              ? Theme.of(context)
                                  .colorScheme
                                  .tertiary
                                  .withOpacity(0.14)
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isOpenList
                              ? Icons.lock_open
                              : Icons.inventory_2_outlined,
                          color: isOpenList
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              myList.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (isOpenList) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Opened items",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isOpenList)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6)),
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
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ));
      },
    );
  }
}
