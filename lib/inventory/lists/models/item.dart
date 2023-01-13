class Item {
  final int id;
  final int listId;
  final String productEan;
  final String? displayName;
  String? expirationDate;
  final String? imageUrl;
  final String? thumbUrl;

  Item(this.id, this.listId, this.productEan,
      {this.expirationDate, this.displayName, this.imageUrl, this.thumbUrl});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
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
