class Item {
  final int id;
  final int listId;
  final String productEan;
  final String displayName;
  String? expirationDate;
  final String? imageUrl;
  final String? thumbUrl;
  final Set<String>? tags;

  Item(this.id, this.listId, this.productEan, this.displayName,
      {this.expirationDate, this.imageUrl, this.thumbUrl, this.tags});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      json['id'],
      json['listId'],
      json['productEan'],
      json['displayName'],
      expirationDate: json['expirationDate'],
      imageUrl: json['imageUrl'],
      thumbUrl: json['thumbUrl'],
      tags: json['tags']
    );
  }
}
