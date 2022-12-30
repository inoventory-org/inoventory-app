import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

abstract class ProductService {

  Future<List<Product>> search(String barcode);
  Future<List<Product>> all();
  Future<Product> add(Product product);
  Future<Product> update(String productId, Product product);
  Future<bool> delete(String productId);

}

class ProductServiceImpl implements ProductService {

  static const backendUrl = Constants.inoventoryBackendUrl;

  @override
  Future<Product> add(Product product) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> all() async {
    final response = await http.get(Uri.parse("$backendUrl/api/v1/products"))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Iterable productsJson = jsonDecode(response.body);
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      // throw Exception('Failed to load products');
      return [];
    }
  }

  @override
  Future<bool> delete(String productId) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> search(String barcode) async {
    final response = await http.get(Uri.parse("$backendUrl/api/v1/products?ean=$barcode"))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {

      String jsonStr = response.body;
      // print(jsonStr);
      Map<String, dynamic> json = jsonDecode(jsonStr);
      Product product = Product.fromJson(json);

      print("MyProduct: $product");
      return <Product>[product];
    }
    else {
      // 3017620425035
      // If the server did not return a 200 OK response,
      // then throw an exception.
      // throw Exception('Failed to load product with barcode: $barcode');
      return <Product>[];
    }
  }

  @override
  Future<Product> update(String productId, Product product) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
