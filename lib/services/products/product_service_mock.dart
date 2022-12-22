import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/services/products/product_service_interface.dart';

class ProductServiceMock implements ProductService {
  final List<Product> products = [
    Product("0", "Bildschirm Reinigungstücher (Feucht)", "4058172924682"),
    Product("1", "Mayo", "40581729246841"),
    Product("2", "Ketchup", "4058172924336"),
    Product("3", "Wasser", "4058172924684"),
    Product("4", "Spaghetti", "4058172924683"),
    Product("5", "Mutti Tomatensoße 400g", "80042556")
  ];

  @override
  Future<List<Product>> search(String barcode) async {
    return Future.delayed(const Duration(seconds: 2), () {
      return products
          .where((product) => product.EAN.startsWith(barcode))
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
