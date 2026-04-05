import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/products/product_model.dart';

abstract class ProductService {
  Future<List<Product>> search(String barcode, {bool fresh = false});

  Future<List<Product>> all();

  Future<Product> add(Product product);

  Future<Product> update(String productId, Product product);

  Future<bool> delete(String productId);

  /// Creates or updates a product in the OpenFoodFacts database.
  ///
  /// Works as an upsert: OFF identifies the product by barcode (EAN).
  /// If the product already exists, its fields will be updated; otherwise it will be created.
  ///
  /// [images] is a map of OFF image field names to local files:
  ///   - "front"       → front-of-pack photo
  ///   - "ingredients" → ingredients list photo
  ///   - "nutrition"   → nutritional info photo
  ///
  /// [region] controls the OFF subdomain (e.g. "world", "de", "us"). Defaults to "world".
  Future<void> upsertToOpenFoodFacts(
    Product product,
    Map<String, File> images, {
    String language = 'en',
    String region = 'world',
    void Function(int sent, int total)? onSendProgress,
  });
}

class ProductServiceImpl implements ProductService {
  final backendUrl = Constants.inoventoryBackendUrl;
  final timeout = const Duration(minutes: 3);
  final Dio dio;

  ProductServiceImpl(this.dio);

  @override
  Future<Product> add(Product product) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> all() async {
    final response =
        await dio.get("$backendUrl/api/v1/products").timeout(timeout);
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

  @override
  Future<void> upsertToOpenFoodFacts(
    Product product,
    Map<String, File> images, {
    String language = 'en',
    String region = 'world',
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formData = FormData();

    // Add text fields
    if (product.name.isNotEmpty) {
      formData.fields.add(MapEntry('productName', product.name));
    }
    if (product.brands != null && product.brands!.isNotEmpty) {
      formData.fields.add(MapEntry('brands', product.brands!));
    }
    if (product.weight != null && product.weight!.isNotEmpty) {
      formData.fields.add(MapEntry('weight', product.weight!));
    }
    formData.fields.add(MapEntry('language', language));
    formData.fields.add(MapEntry('region', region));

    // Add image files
    for (final entry in images.entries) {
      final imageType = entry.key; // "front", "ingredients", or "nutrition"
      final imageFile = entry.value;
      formData.files.add(MapEntry(
        '${imageType}Image',
        await MultipartFile.fromFile(
          imageFile.path,
          filename: '${imageType}.jpg',
        ),
      ));
    }

    try {
      final response = await dio
          .put(
            '$backendUrl/api/v1/products/${product.ean}',
            data: formData,
            onSendProgress: onSendProgress,
          )
          .timeout(timeout);

      if (response.statusCode != 204) {
        throw Exception(_extractErrorMessage(
          statusCode: response.statusCode,
          responseData: response.data,
          fallback:
              'Failed to submit product to Open Food Facts. Please try again.',
        ));
      }
    } on DioException catch (error) {
      throw Exception(
        _extractErrorMessage(
          statusCode: error.response?.statusCode,
          responseData: error.response?.data,
          fallback: error.message ??
              'Failed to submit product to Open Food Facts. Please try again.',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Submitting the product took too long. Please try again.',
      );
    }
  }

  String _extractErrorMessage({
    required int? statusCode,
    required Object? responseData,
    required String fallback,
  }) {
    final extracted = _extractMessageFromResponseData(responseData);
    if (extracted != null && extracted.isNotEmpty) {
      return extracted;
    }
    if (statusCode != null) {
      return 'Request failed with status $statusCode. $fallback';
    }
    return fallback;
  }

  String? _extractMessageFromResponseData(Object? responseData) {
    if (responseData == null) {
      return null;
    }
    if (responseData is String) {
      final trimmed = responseData.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (responseData is Map) {
      for (final key in const ['message', 'error', 'detail', 'debug']) {
        final value = responseData[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return responseData.toString();
    }
    return responseData.toString();
  }
}
