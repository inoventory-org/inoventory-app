class InventoryItem {
  final int id;
  final int listId;
  final String productEan;
  final String? displayName;
  String? expirationDate;

  InventoryItem(this.id, this.listId, this.productEan,
      {this.expirationDate, this.displayName});

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      json['id'],
      json['listId'],
      json['productEan'],
      expirationDate: json['expirationDate'],
      displayName: json['displayName'],
    );
  }
}

class InventoryListItemWrapper {
  final int listId;
  final String productEan;
  final String? displayName;
  final List<InventoryItem> items;

  InventoryListItemWrapper(
      this.listId, this.productEan, this.displayName, this.items);

  factory InventoryListItemWrapper.fromItems(List<InventoryItem> items) {
    return InventoryListItemWrapper(
        items[0].listId, items[0].productEan, items[0].displayName, items);
  }

  int get quantity {
    return items.length;
  }
}
