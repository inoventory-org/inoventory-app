class InventoryListItem {
  final int id;
  final int listId;
  final String productEan;
  String? expirationDate;

  InventoryListItem(this.id, this.listId, this.productEan, {this.expirationDate});

  factory InventoryListItem.fromJson(Map<String, dynamic> json) {
    return InventoryListItem(
      json['id'],
      json['listId'],
      json['productEan'],
      expirationDate: json['expirationDate'],
    );
  }
}