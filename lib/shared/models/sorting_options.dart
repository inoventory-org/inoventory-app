import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/items/item_list_route.dart';

class SortingOptions {
  final List<SORTING> sortOptions;
  final Function onSortingDirectionChange;
  final ValueChanged<SORTING> onSortingKeySelected;

  SortingOptions({required this.sortOptions, required this.onSortingDirectionChange, required this.onSortingKeySelected});
}
