import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/services/products/product_service_interface.dart';

class ProductServiceMock implements ProductService {
  final List<Product> products = [
    Product("Bildschirm Reinigungstücher (Feucht)", "4058172924682"),
    Product("Mayo", "40581729246841"),
    Product("Ketchup", "4058172924336"),
    Product("Wasser", "4058172924684"),
    Product("Spaghetti", "4058172924683"),
    Product("Mutti Tomatensoße 400g", "80042556")
  ];

  @override
  Future<List<Product>> search(String barcode) async {
    return Future.delayed(const Duration(seconds: 2), () {
      return products
          .where((product) => product.ean.startsWith!!(barcode))
          .toList();
    });
  }

  @override
  Future<List<Product>> all() async {
    return Future.delayed(const Duration(seconds: 2), () {
      return products;
    });
  }

  @override
  Future<Product> add(Product product) async {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(String productId) async {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<Product> update(String productId, Product product) async {
    // TODO: implement update
    throw UnimplementedError();
  }
}
