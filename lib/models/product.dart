enum ProductSource { API, USER }

class Product {
  final String id;
  final String categoryId;
  final String name;
  final String EAN;
  final ProductSource source;
  final String? imageUrl;

  Product(this.id, this.categoryId, this.name, this.EAN,
      {this.imageUrl, this.source = ProductSource.USER});
}
