import 'package:inoventory_ui/models/product.dart';

abstract class ProductService {

  Future<List<Product>> search(String barcode);
  Future<List<Product>> all();
  Future<Product> add(Product product);
  Future<Product> update(String productId, Product product);
  Future<bool> delete(String productId);

}