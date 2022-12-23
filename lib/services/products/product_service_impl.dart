import 'dart:convert';

import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/services/products/product_service_interface.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:http/http.dart' as http;

class ProductServiceImpl implements ProductService {

  static const backend_url = Constants.inoventory_backend_url;

  @override
  Future<Product> add(Product product) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> all() async {
    final response = await http.get(Uri.parse("$backend_url/api/v1/products"));
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
    final response = await http.get(Uri.parse("$backend_url/api/v1/products?ean=$barcode"));
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
