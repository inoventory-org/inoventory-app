import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/item_list_route.dart';
import 'package:inoventory_ui/shared/models/sorting_options.dart';

class InoventoryPopupMenu extends StatelessWidget {
  final SortingOptions sortingOptions;


  const InoventoryPopupMenu({super.key, required this.sortingOptions});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SORTING>(
      icon: const Icon(Icons.sort),
      onSelected: sortingOptions.onSortingKeySelected,
      itemBuilder: (BuildContext context) {
        return sortingOptions.sortOptions.map((SORTING option) {
          return PopupMenuItem<SORTING>(
            value: option, // Use lowercase for simplicity
            child: Text('Sort by ${option.name}'),
          );
        }).toList();
      },
    );
  }
}
