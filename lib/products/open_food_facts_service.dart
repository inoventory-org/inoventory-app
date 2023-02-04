import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:openfoodfacts/model/ProductResultV3.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'dart:developer' as developer;


abstract class OpenFoodFactsService {
  Future<ProductResultV3> add(Product product);
}

@Injectable(as: OpenFoodFactsService)
class OpenFoodFactsServiceImpl implements OpenFoodFactsService {
  @override
  Future<ProductResultV3> add(Product product) {
    // TODO: implement add
    throw UnimplementedError();
  }

}