import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/models/item_wrapper.dart';
import 'package:inoventory_ui/inventory/items/widgets/list_widget.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_search_bar.dart';

class ItemSearchRoute extends StatefulWidget {
  final List<ItemWrapper> itemWrappers;
  final Future<bool> Function(ItemWrapper itemWrapper) onDelete;
  final Future<void> Function(ItemWrapper itemWrapper) onEdit;

  const ItemSearchRoute({super.key, required this.itemWrappers, required this.onDelete, required this.onEdit});

  @override
  State<ItemSearchRoute> createState() => _ItemSearchRouteState();
}

class _ItemSearchRouteState extends State<ItemSearchRoute> {
  late List<ItemWrapper> _filteredItemWrappers;

  @override
  void initState() {
    super.initState();
    _filteredItemWrappers = widget.itemWrappers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: InoventorySearchBar(
          // initialValue: widget.initialSearchValue,
          onChanged: onSearchBarChanged,
        ),
        body: InventoryListWidget(
          itemWrappers: _filteredItemWrappers,
          onDelete: widget.onDelete,
          onEdit: widget.onEdit,
        ));
  }

  onSearchBarChanged(String? searchString) {
    searchString = searchString?.trim() ?? "";
    if (searchString == "") {
      setState(() {
        _filteredItemWrappers = widget.itemWrappers;
      });
      return;
    }

    setState(() {
      _filteredItemWrappers = widget.itemWrappers.where((itemWrapper) => search(itemWrapper, searchString!)).toList();
    });
  }

  bool search(ItemWrapper itemWrapper, String searchString) {
    searchString = searchString.toLowerCase();
    Set<String> itemTags = itemWrapper.items.where((item) => item.tags != null).expand((item) => item.tags!).map((tag) => tag.toLowerCase()).toSet();
    return itemWrapper.displayName.toLowerCase().contains(searchString) || itemTags.contains(searchString);
  }
}
