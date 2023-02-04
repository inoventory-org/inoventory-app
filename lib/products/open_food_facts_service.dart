import 'dart:async';
import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:inoventory_ui/products/product_model.dart' as inoventory;
import 'package:openfoodfacts/model/ProductResultV3.dart';
import 'package:openfoodfacts/model/UserAgent.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/config/secrets.dart';
import 'dart:developer' as developer;
import 'package:openfoodfacts/utils/OpenFoodAPIConfiguration.dart';
import 'package:openfoodfacts/utils/QueryType.dart';

abstract class OpenFoodFactsService {
  Future<Product?> addProduct(
      inoventory.Product inoProduct, Map<ImageField, File>? images);
  Future<Product?> getProduct(String barcode);
}


@Injectable(as: OpenFoodFactsService)
class OpenFoodFactsServiceImpl implements OpenFoodFactsService {
  final User myUser = const User(
      userId: "off", //Constants.openFoodFactsUserName,
      password: "off"); // Secrets.openFoodFactsToken);

  OpenFoodFactsServiceImpl() : super() {
    OpenFoodAPIConfiguration.userAgent = const UserAgent(name: Constants.appName);
    OpenFoodAPIConfiguration.globalUser = myUser;
    OpenFoodAPIConfiguration.globalQueryType = QueryType.PROD;
  }

  @override
  Future<Product?> addProduct(inoventory.Product inoProduct, Map<ImageField, File>? images) async {

    Product product = convertLocalProductToOffProduct(inoProduct);
    Status result = await OpenFoodAPIClient.saveProduct(myUser, product);
    if (result.status != 1) {
      throw Exception('product could not be added: ${result.status}:${result.error}');
    }

    // supplement images
    images?.entries.forEach((entry) async {
      ImageField imageField = entry.key;
      File imageFile = entry.value;

      SendImage image = SendImage(
        lang: OpenFoodFactsLanguage.ENGLISH,
        barcode: product.barcode!,
        imageField: imageField,
        imageUri: Uri.parse(imageFile.path),
      );

      // query the OpenFoodFacts API
      Status result = await OpenFoodAPIClient.addProductImage(myUser, image);

      if (result.status != 'status ok') {
        throw Exception(
            '$imageField image could not be uploaded: ${result.error} ${result.imageId.toString()}');
      }
    });

    // retrieve newly created product
    try {
      Product? newProduct = await getProduct(inoProduct.ean);
      return newProduct;
    } catch (e) {
      developer.log("Newly created product could not be retrieved", error: e);
      rethrow;
    }
  }

  @override
  Future<Product?> getProduct(String barcode) async {
    final ProductQueryConfiguration configuration = ProductQueryConfiguration(
      barcode,
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: [ProductField.ALL],
      version: ProductQueryVersion.v3,
    );
    final ProductResultV3 result =
    await OpenFoodAPIClient.getProductV3(configuration);

    if (result.status == ProductResultV3.statusSuccess) {
      return result.product;
    } else {
      throw Exception('product not found, please insert data for $barcode');
    }
  }

  Product convertLocalProductToOffProduct(inoventory.Product inoProduct) {
    return Product(
        barcode: inoProduct.ean,
        productName: inoProduct.name,
        quantity: inoProduct.weight);
  }

  inoventory.Product convertOffProductToInoventoryProduct(Product offProduct) {
    return inoventory.Product(offProduct.barcode!, offProduct.productName!,
        ean: offProduct.barcode!, weight: offProduct.quantity);
  }

}
