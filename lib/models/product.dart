enum ProductSource {
  API, USER
}

class Product {
  final String name;
  final String ean;
  final String? id;
  final List<String>? tags;
  // final String? source;
  // final String? imageUrl;

  Product(this.name, this.ean, {this.id, this.tags});
  // Product(this.id, this.name, this.EAN,
  //     {this.tags, this.imageUrl, this.source = "USER"});

  /**
   * "id": null,
      "name": "Nutella",
      "ean": "3017620425035",
      "tags": []
   */
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
        json['name'],
        json['ean'],
        id: json['id'] == null ? "some-id" : json['id'].toString(),
        tags: <String>[] // TODO: change
        // source: json['source'],
        // imageUrl: json['imageUrl']
    );
  }
}
