import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/products/product_model.dart';

abstract class ProductService {
  Future<List<Product>> search(String barcode, {bool fresh = false});

  Future<List<Product>> all();

  Future<Product> add(Product product);

  Future<Product> update(String productId, Product product);

  Future<bool> delete(String productId);
}

@Injectable(as: ProductService)
class ProductServiceImpl implements ProductService {
  final backendUrl = Constants.inoventoryBackendUrl;
  final timeout = const Duration(seconds: 5);
  final Dio dio;

  ProductServiceImpl(this.dio);

  @override
  Future<Product> add(Product product) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> all() async {
    final response = await dio.get("$backendUrl/api/v1/products").timeout(timeout);
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Iterable productsJson = response.data;
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
  Future<List<Product>> search(String barcode, {bool fresh = false}) async {
    final freshStr = fresh ? "&fresh=true" : "&fresh=false";
    final url = "$backendUrl/api/v1/products?ean=$barcode$freshStr";
    print("Fetching: $url");
    final response = await dio.get(url).timeout(timeout);
    if (response.statusCode == 200) {
      Product product = Product.fromJson(response.data);
      return <Product>[product];
    } else {
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
