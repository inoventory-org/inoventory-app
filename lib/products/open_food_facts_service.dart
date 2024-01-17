import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/config/secrets.dart';
import 'package:inoventory_ui/products/product_model.dart' as inoventory;
import 'package:openfoodfacts/openfoodfacts.dart';

abstract class OpenFoodFactsService {
  Future<void> addProduct(inoventory.Product inoProduct, Map<ImageField, File>? images);
  Future<Product?> getProduct(String barcode);
}

@Injectable(as: OpenFoodFactsService)
class OpenFoodFactsServiceImpl implements OpenFoodFactsService {
  final User myUser = const User(userId: Constants.openFoodFactsUserName, password: Secrets.openFoodFactsToken);

  OpenFoodFactsServiceImpl() : super() {
    OpenFoodAPIConfiguration.userAgent = UserAgent(name: Constants.appName, version: Constants.version, comment: "(eilabouni.rudy@gmail.com)");
    OpenFoodAPIConfiguration.globalUser = myUser;
    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.GERMANY;
    OpenFoodAPIConfiguration.globalLanguages = [OpenFoodFactsLanguage.GERMAN, OpenFoodFactsLanguage.ENGLISH];
  }

  @override
  Future<void> addProduct(inoventory.Product inoProduct, Map<ImageField, File>? images) async {
    Product product = convertLocalProductToOffProduct(inoProduct);
    Status result = await OpenFoodAPIClient.saveProduct(
      myUser,
      product,
      uriHelper: uriHelperFoodTest,
    );

    if (result.status != 1) {
      throw Exception('product could not be added: ${result.status}:${result.error}');
    }

    // supplement images
    images?.entries.forEach((entry) async {
      ImageField imageField = entry.key;
      File imageFile = entry.value;
      SendImage image = SendImage(
        lang: OpenFoodFactsLanguage.GERMAN,
        barcode: product.barcode!,
        imageField: imageField,
        imageUri: Uri.parse(imageFile.path),
      );

      // query the OpenFoodFacts API
      Status result = await OpenFoodAPIClient.addProductImage(myUser, image, uriHelper: uriHelperFoodTest);
      developer.log("result.status: ${result.status}");
      developer.log("result.statusVerbose: ${result.statusVerbose}");
      developer.log("result.body: ${result.body}");
      developer.log("result.error: ${result.error}");
      developer.log("result.imageId: ${result.imageId}");
      if (result.status  != "status ok") {
        throw Exception('$imageField image could not be uploaded: ${result.error} ${result.imageId.toString()}');
      }
    });

    //
    // // retrieve newly created product
    // try {
    //   Product? newProduct = await getProduct(inoProduct.ean);
    //   return newProduct;
    // } catch (e) {
    //   developer.log("Newly created product could not be retrieved", error: e);
    //   rethrow;
    // }
  }

  @override
  Future<Product?> getProduct(String barcode) async {
    final ProductQueryConfiguration configuration = ProductQueryConfiguration(
      barcode,
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: [ProductField.ALL],
      version: ProductQueryVersion.v3,
    );
    final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(configuration);

    if (result.status == ProductResultV3.statusSuccess) {
      return result.product;
    } else {
      throw Exception('product not found, please insert data for $barcode');
    }
  }

  Product convertLocalProductToOffProduct(inoventory.Product inoProduct) {
    return Product(barcode: inoProduct.ean, productName: inoProduct.name, brands: inoProduct.brands, quantity: inoProduct.weight);
  }

  inoventory.Product convertOffProductToInoventoryProduct(Product offProduct) {
    return inoventory.Product(offProduct.barcode!, offProduct.productName!, ean: offProduct.barcode!, brands: offProduct.brands, weight: offProduct.quantity);
  }
}
