enum ProductSource {
  API, USER
}

class Product {
  final String id;
  final String name;
  final String EAN;
  final String source;
  final String? imageUrl;

  Product(this.id, this.name, this.EAN,
      {this.imageUrl, this.source = "USER"});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
        json['id'].toString(),
        json['name'],
        json['ean'],
        source: json['source'],
        imageUrl: json['imageUrl']
    );
  }
}
