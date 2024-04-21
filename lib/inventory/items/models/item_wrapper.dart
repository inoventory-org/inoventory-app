import 'package:inoventory_ui/inventory/items/models/item.dart';

/**
 * An itemWrapper is the object that is actually shown inside an inventory list.
 * It contains the product information as well as the concrete individual instances of the item which have their own expiry date and unique informatio
 */
class ItemWrapper {
  final int listId;
  final String productEan;
  final String displayName;
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

  factory ItemWrapper.fromJson(Map<String, dynamic> json) {
    var items = (json['items'] as List).map((item) => Item.fromJson(item)).toList();
    return ItemWrapper(
        json['listId'],
        json['productEan'],
        json['displayName'] ?? "unknown name",
        items.first.imageUrl ?? json['imageUrl'],
        items.first.thumbUrl ?? json['thumbUrl'],
        items
    );
  }

  int get quantity => items.length;
}
