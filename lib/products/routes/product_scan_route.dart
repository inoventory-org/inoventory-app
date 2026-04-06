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

  const ProductScanRoute({super.key, required this.inventoryList});

  @override
  State<ProductScanRoute> createState() => _ProductScanRouteState();
}

class _ProductScanRouteState extends State<ProductScanRoute> {
  static const Duration _barcodeSuccessCooldown = Duration(milliseconds: 900);

  final ProductService _productService = getIt<ProductService>();
  final ExpiryScanController _expiryScanController = ExpiryScanController();
  final ExpiryDateParser _expiryDateParser = ExpiryDateParser();
  String _barcode = "";
  bool _productFound = true;
  Product? _product;
  bool _isHandlingUnknownBarcode = false;
  bool _showModeFlash = false;
  String _modeFlashLabel = 'Barcode Scan';
  Timer? _modeFlashTimer;
  Timer? _barcodeCooldownTimer;
  bool _lastExpiryModeActive = false;
  bool _isLookingUpBarcode = false;
  bool _isBarcodeCooldownActive = false;
  int _barcodeLookupRequestId = 0;
  int _barcodeScannerSession = 0;
  double _sheetDragDismissDistance = 0;
  bool _isDraggingSheet = false;

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

  @override
  void initState() {
    super.initState();
    _lastExpiryModeActive = _expiryScanController.isActive;
    _expiryScanController.addListener(_handleExpiryModeChange);
  }

  void _handleExpiryModeChange() {
    final bool isExpiryModeActive = _expiryScanController.isActive;
    if (_lastExpiryModeActive == isExpiryModeActive || !mounted) {
      return;
    }
    _lastExpiryModeActive = isExpiryModeActive;
    _modeFlashTimer?.cancel();
    setState(() {
      _showModeFlash = true;
      _modeFlashLabel =
          isExpiryModeActive ? 'Expiry Scan Mode' : 'Barcode Scan Mode';
    });
    _modeFlashTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showModeFlash = false;
      });
    });
  }

  void _dismissActiveProductSheet() {
    _expiryScanController.stopScanning();
    _resetBarcodeDetectionState();
    setState(() {
      _sheetDragDismissDistance = 0;
      _isDraggingSheet = false;
      _product = null;
      _barcode = "";
      _productFound = false;
    });
  }

  void _resetBarcodeDetectionState() {
    _barcodeCooldownTimer?.cancel();
    _isBarcodeCooldownActive = false;
    _isLookingUpBarcode = false;
    _barcodeLookupRequestId++;
    _barcodeScannerSession++;
  }

  void _onSheetHandleDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy <= 0) {
      setState(() {
        _sheetDragDismissDistance = 0;
        _isDraggingSheet = false;
      });
      return;
    }
    setState(() {
      _isDraggingSheet = true;
      _sheetDragDismissDistance =
          (_sheetDragDismissDistance + details.delta.dy).clamp(0.0, 220.0);
    });
  }

  void _onSheetHandleDragEnd(DragEndDetails details) {
    final bool shouldDismiss = _sheetDragDismissDistance > 36 ||
        (details.primaryVelocity != null && details.primaryVelocity! > 500);
    if (shouldDismiss) {
      _dismissActiveProductSheet();
      return;
    }
    setState(() {
      _sheetDragDismissDistance = 0;
      _isDraggingSheet = false;
    });
  }

  dynamic onDetect(BarcodeCapture barcodeCapture) async {
    if (_isHandlingUnknownBarcode ||
        _isLookingUpBarcode ||
        _isBarcodeCooldownActive) {
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

      final int requestId = ++_barcodeLookupRequestId;
      _isLookingUpBarcode = true;
      List<Product> products = [];
      try {
        products = await _productService.search(code,
            fresh: Globals.forceFetchProducts);
      } catch (e) {
        _isLookingUpBarcode = false;
        onFailedToLookupBarcode(code);
        developer.log("An error occurred while looking up barcode $code",
            error: e);
        return;
      }
      _isLookingUpBarcode = false;

      if (!mounted || requestId != _barcodeLookupRequestId || _product != null) {
        return;
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
      if (products.isNotEmpty) {
        _barcodeCooldownTimer?.cancel();
        _isBarcodeCooldownActive = true;
        _barcodeCooldownTimer = Timer(_barcodeSuccessCooldown, () {
          _isBarcodeCooldownActive = false;
        });
      }
      if (products.isEmpty && mounted) {
        unawaited(_promptToAddUnknownProduct(code));
      }
      debugPrint("Product Found: $_productFound");
    }
  }

  @override
  void dispose() {
    _modeFlashTimer?.cancel();
    _barcodeCooldownTimer?.cancel();
    _expiryScanController.removeListener(_handleExpiryModeChange);
    _expiryScanController.dispose();
    super.dispose();
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_isHandlingUnknownBarcode)
                      Container(
                        key: const ValueKey('unknown-product-pane'),
                        color: Colors.black,
                      )
                    else if (hasProduct &&
                        _expiryScanController.awaitingConfirmation)
                      _ExpiryConfirmationPane(
                        key: ValueKey(
                          'expiry-confirm-${_expiryScanController.targetRowIndex ?? 0}',
                        ),
                      )
                    else if (hasProduct && _expiryScanController.isActive)
                      ExpiryScanCameraPane(
                        key: ValueKey(
                          'expiry-${_expiryScanController.targetRowIndex ?? 0}',
                        ),
                        controller: _expiryScanController,
                        parser: _expiryDateParser,
                      )
                    else
                      BarcodeScannerPane(
                        key: ValueKey('barcode-pane-$_barcodeScannerSession'),
                        onDetect: onDetect,
                        enableDetection: !hasProduct,
                      ),
                    IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _showModeFlash ? 1 : 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 18,
                      left: 18,
                      right: 18,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 220),
                        offset: _showModeFlash
                            ? Offset.zero
                            : const Offset(0, -0.3),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _showModeFlash ? 1 : 0,
                          child: Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.7),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    blurRadius: 14,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _expiryScanController.isActive
                                          ? Icons.document_scanner_outlined
                                          : Icons.qr_code_scanner,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _modeFlashLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _barcode != ""
                  ? Expanded(
                      flex: 7,
                      child: _productFound
                          ? AnimatedContainer(
                              duration: _isDraggingSheet
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              transform: Matrix4.translationValues(
                                0,
                                _sheetDragDismissDistance,
                                0,
                              ),
                              child: Opacity(
                                opacity: (1 - (_sheetDragDismissDistance / 260))
                                    .clamp(0.72, 1.0),
                                child: Column(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _dismissActiveProductSheet,
                                  onVerticalDragUpdate:
                                      _onSheetHandleDragUpdate,
                                  onVerticalDragEnd: _onSheetHandleDragEnd,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4, bottom: 6),
                                    child: Center(
                                      child: Container(
                                        width: 46,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.22),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: AddItemView(
                                    _product!,
                                    widget.inventoryList,
                                    expiryScanController: _expiryScanController,
                                    onDismiss: _dismissActiveProductSheet,
                                    postAddCallback: () {
                                      _expiryScanController.stopScanning();
                                      _resetBarcodeDetectionState();
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
                                      scaffoldMessenger.showSnackBar(
                                        _getSnackBar(
                                          "Successfully added item",
                                          Colors.green,
                                        ),
                                      );
                                    },
                                    onError: (item) {
                                      final scaffoldMessenger =
                                          ScaffoldMessenger.of(context);
                                      scaffoldMessenger.showSnackBar(
                                        _getSnackBar(
                                          "Failed to add item",
                                          Colors.red,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                                ),
                              ),
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
}

class _ExpiryConfirmationPane extends StatelessWidget {
  const _ExpiryConfirmationPane({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.secondaryContainer.withValues(alpha: 0.92),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.98),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ConfirmationPanePatternPainter(
                color: colorScheme.secondary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.document_scanner_outlined,
                      color: colorScheme.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Expiry Captured',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review the detected date in the popup, or retry to scan again.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationPanePatternPainter extends CustomPainter {
  final Color color;

  const _ConfirmationPanePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const double gap = 26;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfirmationPanePatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
