import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/ean/scanner.dart';
import 'package:inoventory_ui/expiry_scan/controllers/expiry_scan_controller.dart';
import 'package:inoventory_ui/expiry_scan/expiry_date_parser.dart';
import 'package:inoventory_ui/expiry_scan/widgets/expiry_scan_camera_pane.dart';
import 'package:inoventory_ui/inventory/items/widgets/add_item.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/routes/add_product_route.dart';
import 'package:inoventory_ui/products/product_service.dart';
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
  final ExpiryScanController _expiryScanController = ExpiryScanController();
  final ExpiryDateParser _expiryDateParser = ExpiryDateParser();
  String _barcode = "";
  bool _productFound = true;
  Product? _product;
  bool _isHandlingUnknownBarcode = false;

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

  Future<void> onSuccessfulProductAddition(String barcode) async {
    try {
      final products = await _productService.search(barcode, fresh: true);
      if (!mounted) return;
      setState(() {
        _barcode = barcode;
        if (products.isNotEmpty) {
          _product = products.last;
          _productFound = true;
        } else {
          _product = null;
          _productFound = false;
        }
      });
    } catch (e) {
      onErrorProductAddition(e);
      return;
    }
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
        _getSnackBar("Successfully added new product", Colors.green));
  }

  void onErrorProductAddition(Object e) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(_getSnackBar(
        "Failed to add new product item: ${e.toString()}", Colors.red));
  }

  Future<void> _promptToAddUnknownProduct(String barcode) async {
    if (_isHandlingUnknownBarcode) {
      return;
    }
    setState(() {
      _isHandlingUnknownBarcode = true;
    });

    final shouldAdd = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unknown Barcode'),
            content: Text(
              'Barcode $barcode is not known yet. Do you want to add it as a new product?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldAdd && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddProductRoute(
            barcode: barcode,
            onSuccessfulProductAddition: onSuccessfulProductAddition,
          ),
        ),
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isHandlingUnknownBarcode = false;
    });
  }

  dynamic onDetect(BarcodeCapture barcodeCapture) async {
    if (_isHandlingUnknownBarcode) {
      return;
    }
    if (_product != null) {
      return;
    }
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
        products = await _productService.search(code,
            fresh: Globals.forceFetchProducts);
      } catch (e) {
        onFailedToLookupBarcode(code);
        developer.log("An error occurred while looking up barcode $code",
            error: e);
      }
      setState(() {
        if (products.isNotEmpty) {
          _barcode = code;
          _product = products.last;
          _productFound = true;
        } else {
          _barcode = "";
          _product = null;
          _productFound = false;
        }
      });
      if (products.isEmpty && mounted) {
        unawaited(_promptToAddUnknownProduct(code));
      }
      debugPrint("Product Found: $_productFound");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _expiryScanController,
        builder: (context, _) {
          final bool hasProduct =
              _barcode.isNotEmpty && _productFound && _product != null;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: hasProduct ? 3 : 4,
                child: _isHandlingUnknownBarcode
                    ? Container(color: Colors.black)
                    : hasProduct && _expiryScanController.isActive
                        ? ExpiryScanCameraPane(
                            key: ValueKey(
                                'expiry-${_expiryScanController.targetRowIndex}-${_expiryScanController.eventId}'),
                            controller: _expiryScanController,
                            parser: _expiryDateParser,
                          )
                        : BarcodeScannerPane(
                            key: const ValueKey('barcode-pane'),
                            onDetect: onDetect,
                            enableDetection: !hasProduct,
                          ),
              ),
              _barcode != ""
                  ? Expanded(
                      flex: 7,
                      child: _productFound
                          ? AddItemView(
                              _product!,
                              widget.inventoryList,
                              expiryScanController: _expiryScanController,
                              postAddCallback: () {
                                _expiryScanController.stopScanning();
                                setState(() {
                                  _product = null;
                                  _barcode = "";
                                  _productFound = false;
                                });
                              },
                              onSuccess: (item) {
                                final scaffoldMessenger =
                                    ScaffoldMessenger.of(context);
                                scaffoldMessenger.clearSnackBars();
                                scaffoldMessenger.showSnackBar(_getSnackBar(
                                    "Successfully added item", Colors.green));
                              },
                              onError: (item) {
                                final scaffoldMessenger =
                                    ScaffoldMessenger.of(context);
                                scaffoldMessenger.showSnackBar(_getSnackBar(
                                    "Failed to add item", Colors.red));
                              },
                            )
                          : const SizedBox.shrink(),
                    )
                  : const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _expiryScanController.dispose();
    super.dispose();
  }
}
