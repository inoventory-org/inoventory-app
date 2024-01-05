import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/ean/scanner.dart';
import 'package:inoventory_ui/inventory/items/widgets/add_item.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/widgets/add_product.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ProductScanRoute extends StatefulWidget {
  final InventoryList inventoryList;

  const ProductScanRoute({Key? key, required this.inventoryList})
      : super(key: key);

  @override
  State<ProductScanRoute> createState() => _ProductScanRouteState();
}

class _ProductScanRouteState extends State<ProductScanRoute> {
  final ProductService _productService = getIt<ProductService>();
  String _barcode = "";
  bool _productFound = true;
  Product? _product;

  SnackBar _getSnackBar(String text, Color color) {
    TextStyle style = const TextStyle(color: Colors.white);
    return SnackBar(content: Text(text, style: style), backgroundColor: color);
  }

  void onFailedToLookupBarcode(String barcode) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
        _getSnackBar("Failed to lookup barcode $barcode", Colors.red));
  }

  void onSuccessfulProductAddition(String barcode) {
    setState(() {
      _barcode = "";
    });
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
        _getSnackBar("Successfully added new product", Colors.green));
  }

  void onErrorProductAddition(Object e) {
    setState(() {
      _barcode = "";
    });
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(_getSnackBar(
        "Failed to add new product item: ${e.toString()}", Colors.red));
  }

  void onCancelProductAddition() {
    setState(() {
      _barcode = "";
    });
  }

  dynamic onDetect(BarcodeCapture barcodeCapture) async {
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) {
      debugPrint('Failed to scan Barcode');
    } else {
      final String code = barcodes.first.rawValue ?? "";
      if (code == "") {
        debugPrint('Failed to parse barcode from scanner: ${barcodes.first}');
        return;
      }
      debugPrint('Barcode found! $code');
      if (code == _barcode) {
        return;
      }

      List<Product> products = [];
      try {
        products = await _productService.search(code, fresh: Globals.forceFetchProducts);
      } catch (e) {
        onFailedToLookupBarcode(code);
        developer.log("An error occurred while looking up barcode $code",
            error: e);
      }
      setState(() {
        _barcode = code;
        if (products.isNotEmpty) {
          _product = products.last;
          _productFound = true;
        } else {
          _productFound = false;
          _product = null;
        }
      });
      debugPrint("Product Found: $_productFound");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Expanded(flex: 3, child: BarcodeScannerWidget(onDetect: onDetect)),
      _barcode != ""
          ? Expanded(
              flex: 7,
              child: _productFound
                  ? AddItemView(
                      _product!,
                      widget.inventoryList,
                      postAddCallback: () {
                        setState(() {
                          _product = null;
                          _barcode = "";
                          _productFound = false;
                        });
                      },
                      onSuccess: (item) {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.clearSnackBars();
                        scaffoldMessenger.showSnackBar(_getSnackBar(
                            "Successfully added item", Colors.green));
                      },
                      onError: (item) {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.showSnackBar(
                            _getSnackBar("Failed to add item", Colors.red));
                      },
                    )
                  : AddProductView(
                      barcode: _barcode,
                      onCancelProductAddition: onCancelProductAddition,
                      onSuccessfulProductAddition: onSuccessfulProductAddition,
                      onErrorProductAddition: onErrorProductAddition,
                    ),
            )
          : const SizedBox.shrink() // empty widget
    ]));
  }
}
