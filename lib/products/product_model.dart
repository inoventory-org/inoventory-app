enum ProductSource { api, user }

class Product {
  final String id;
  final String name;
  final String ean;
  final String? brands;
  final String? weight;
  final List<String>? tags;
  final String? source;
  final String? imageUrl;
  final String? thumbUrl;

  Product(this.id, this.name,
      {required this.ean,
      this.brands,
      this.weight,
      this.tags,
      this.source,
      this.imageUrl,
      this.thumbUrl});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      json['id'] == null ? "some-id" : json['id'].toString(),
      json['name'],
      ean: json['ean'],
      brands: json['brands'],
      weight: json['weight'],
      tags: <String>[], // TODO: change
      source: json['source'],
      imageUrl: json['imageUrl'],
      thumbUrl: json['thumbUrl'],
    );
  }
}
