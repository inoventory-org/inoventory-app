class InventoryListItem {
  final int id;
  final int listId;
  final String productEan;
  final String? displayName;
  String? expirationDate;

  InventoryListItem(this.id, this.listId, this.productEan,
      {this.expirationDate, this.displayName});

  factory InventoryListItem.fromJson(Map<String, dynamic> json) {
    return InventoryListItem(
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
  final List<InventoryListItem> items;

  InventoryListItemWrapper(
      this.listId, this.productEan, this.displayName, this.items);

  factory InventoryListItemWrapper.fromItems(List<InventoryListItem> items) {
    return InventoryListItemWrapper(
        items[0].listId, items[0].productEan, items[0].displayName, items);
  }

  int get quantity {
    return items.length;
  }
}
