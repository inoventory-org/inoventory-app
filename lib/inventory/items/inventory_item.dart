class InventoryItem {
  final int id;
  final int listId;
  final String productEan;
  final String? displayName;
  String? expirationDate;
  final String? imageUrl;
  final String? thumbUrl;

  InventoryItem(this.id, this.listId, this.productEan,
      {this.expirationDate, this.displayName, this.imageUrl, this.thumbUrl});

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      json['id'],
      json['listId'],
      json['productEan'],
      expirationDate: json['expirationDate'],
      displayName: json['displayName'],
      imageUrl: json['imageUrl'],
      thumbUrl: json['thumbUrl'],
    );
  }
}

class InventoryListItemWrapper {
  final int listId;
  final String productEan;
  final String? displayName;
  final String? imageUrl;
  final String? thumbUrl;
  final List<InventoryItem> items;

  InventoryListItemWrapper(this.listId, this.productEan, this.displayName,
      this.imageUrl, this.thumbUrl, this.items);

  factory InventoryListItemWrapper.fromItems(List<InventoryItem> items) {
    final item = items.first;
    return InventoryListItemWrapper(item.listId, item.productEan,
        item.displayName, item.imageUrl, item.thumbUrl, items);
  }

  int get quantity => items.length;
}
