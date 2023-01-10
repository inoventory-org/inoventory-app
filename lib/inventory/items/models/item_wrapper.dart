import 'package:inoventory_ui/inventory/items/models/item.dart';

class ItemWrapper {
  final int listId;
  final String productEan;
  final String? displayName;
  final String? imageUrl;
  final String? thumbUrl;
  final List<Item> items;

  ItemWrapper(this.listId, this.productEan, this.displayName, this.imageUrl,
      this.thumbUrl, this.items);

  factory ItemWrapper.fromItems(List<Item> items) {
    final item = items.first;
    return ItemWrapper(item.listId, item.productEan, item.displayName,
        item.imageUrl, item.thumbUrl, items);
  }

  int get quantity => items.length;
}
