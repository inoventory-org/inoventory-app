import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/ean/scanner.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/widgets/add_product.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ProductScanRoute extends StatefulWidget {
  final InventoryList inventoryList;

  ProductScanRoute({Key? key, required this.inventoryList}) : super(key: key);

  @override
  State<ProductScanRoute> createState() => _ProductScanRouteState();
}

class _ProductScanRouteState extends State<ProductScanRoute> {
  final ProductService _productService = getIt<ProductService>();
  String _barcode = "";
  Product? _product;

  SnackBar _getSnackBar(String text, Color color) {
    TextStyle style = const TextStyle(color: Colors.white);
    return SnackBar(content: Text(text, style: style), backgroundColor: color);
  }

  dynamic onDetect(Barcode barcode, MobileScannerArguments? args) async {
    if (barcode.rawValue == null) {
      debugPrint('Failed to scan Barcode');
    } else {
      final String code = barcode.rawValue!;
      debugPrint('Barcode found! $code');
      List<Product> products = await _productService.search(code);
      setState(() {
        _barcode = code;
        if (products.isNotEmpty) {
          _product = products.last;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Expanded(flex: 3, child: BarcodeScannerWidget(onDetect: onDetect)),
      _product != null
          ? Expanded(
              flex: 7,
              child: AddProductView(
                _product!,
                widget.inventoryList,
                postAddCallback: () {
                  setState(() {
                    _product = null;
                    _barcode = "";
                  });
                  // Navigator.of(context).pop();
                },
                onSuccess: (item) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                      _getSnackBar("Successfully added item", Colors.green));
                },
                onError: (item) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                      _getSnackBar("Failed to add item", Colors.green));
                },
              ),
            )
          : const SizedBox.shrink() // empty widget
    ]));
  }
}
