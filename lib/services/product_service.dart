import 'package:inoventory_ui/models/product.dart';

class ProductService {

  final List<Product> products = [
    Product("0", "0", "Bildschirm Reinigungstücher (Feucht)", "4058172924682"),
    Product("1", "1", "Mayo", "40581729246841"),
    Product("2", "2", "Ketchup", "4058172924336"),
    Product("3", "3", "Wasser", "4058172924684"),
    Product("4", "4", "Spaghetti", "4058172924683")
  ];

  List<Product> search(String barcode) {
    return products.where((product) => product.EAN.startsWith(barcode)).toList();
  }

  List<Product> all() {
    return products;
  }

}