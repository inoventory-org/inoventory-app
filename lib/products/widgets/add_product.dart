import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/product_upload_job_service.dart';
import 'package:inoventory_ui/settings/off_settings_service.dart';

// Note: the OpenFoodFacts Dart SDK implementation is kept below, commented out,
// so it can be reactivated easily if needed in the future.
// import 'package:inoventory_ui/products/open_food_facts_service.dart';
// import 'package:openfoodfacts/openfoodfacts.dart' as off;

class AddProductView extends StatefulWidget {
  String barcode;
  final Product? initialProduct;
  final Map<String, File> initialImages;
  final String? initialRegion;
  final String? initialLanguage;
  final String? initialErrorMessage;
  final String submitButtonLabel;
  final String successMessage;
  void Function() onCancelProductAddition;
  FutureOr<void> Function(String barcode)? onSuccessfulProductAddition;
  void Function(Object e)? onErrorProductAddition;
  final Future<void> Function(
    Product product,
    Map<String, File> images,
    String language,
    String region,
  )? onSubmitProduct;

  AddProductView(
      {super.key,
      this.barcode = "",
      this.initialProduct,
      this.initialImages = const {},
      this.initialRegion,
      this.initialLanguage,
      this.initialErrorMessage,
      this.submitButtonLabel = "Add Product",
      this.successMessage = "Product upload queued",
      required this.onCancelProductAddition,
      this.onSuccessfulProductAddition,
      this.onErrorProductAddition,
      this.onSubmitProduct});

  @override
  _AddProductViewState createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  final ProductUploadJobService _jobService = getIt<ProductUploadJobService>();
  final OffSettingsService _settingsService = getIt<OffSettingsService>();
  // Commented out: direct OFF SDK integration (kept for future reference)
  // final OpenFoodFactsService _oFFService = getIt<OpenFoodFactsService>();

  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _weightController = TextEditingController();
  late ImagePicker imagePicker;
  XFile? _frontImage;
  XFile? ingredientsImage;
  XFile? _nutritionImage;
  bool isWorking = false;
  String? _errorMessage;

  String _region = OffSettingsService.defaultRegion;
  String _language = OffSettingsService.defaultLanguage;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    _barcodeController.text = widget.initialProduct?.ean ?? widget.barcode;
    _productNameController.text = widget.initialProduct?.name ?? "";
    _brandController.text = widget.initialProduct?.brands ?? "";
    _weightController.text = widget.initialProduct?.weight ?? "";
    _frontImage = _xFileFromInitialImage('front');
    ingredientsImage = _xFileFromInitialImage('ingredients');
    _nutritionImage = _xFileFromInitialImage('nutrition');
    _errorMessage = widget.initialErrorMessage;
    _region = widget.initialRegion ?? OffSettingsService.defaultRegion;
    _language = widget.initialLanguage ?? OffSettingsService.defaultLanguage;
    if (widget.initialRegion == null || widget.initialLanguage == null) {
      _loadContributionSettings();
    }
  }

  XFile? _xFileFromInitialImage(String imageType) {
    final image = widget.initialImages[imageType];
    if (image == null) {
      return null;
    }
    return XFile(image.path);
  }

  Future<void> _loadContributionSettings() async {
    final settings = await _settingsService.loadContributionSettings();
    if (!mounted) return;
    setState(() {
      _region = settings.region;
      _language = settings.language;
    });
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final image = await imagePicker.pickImage(
          source: ImageSource.camera, imageQuality: 50);
      if (image != null) {
        setState(() {
          if (imageType == 'nutrition') {
            _nutritionImage = image;
          } else if (imageType == 'ingredients') {
            ingredientsImage = image;
          } else {
            _frontImage = image;
          }
        });
        _showSnackbar(
            "Long press on the added image to clear it", Colors.green);
      }
    } catch (error) {
      developer.log("error: $error");
    }
  }

  Future<void> _clearImage(String imageType) async {
    setState(() {
      if (imageType == 'front') {
        _frontImage = null;
      } else if (imageType == 'ingredients') {
        ingredientsImage = null;
      } else {
        _nutritionImage = null;
      }
    });
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final product = Product(
      _barcodeController.text,
      _productNameController.text,
      ean: _barcodeController.text,
      brands: _brandController.text,
      weight: _weightController.text,
    );

    final Map<String, File> images = {
      if (_frontImage != null) 'front': File(_frontImage!.path),
      if (ingredientsImage != null) 'ingredients': File(ingredientsImage!.path),
      if (_nutritionImage != null) 'nutrition': File(_nutritionImage!.path),
    };

    try {
      setState(() {
        isWorking = true;
        _errorMessage = null;
      });

      // Submit via Inoventory backend → backend forwards to OpenFoodFacts
      if (widget.onSubmitProduct != null) {
        await widget.onSubmitProduct!(product, images, _language, _region);
      } else {
        await _jobService.enqueueUpsert(
          product: product,
          images: images,
          language: _language,
          region: _region,
          actionLabel:
              widget.initialProduct == null ? 'Product upload' : 'Product edit',
        );
      }

      // ── Alternative: submit directly to OpenFoodFacts using the OFF Dart SDK ──────────────────
      // (Kept commented out for easy reactivation if the backend-proxy approach is abandoned.)
      //
      // final offProduct = off.Product(
      //   barcode: product.ean,
      //   productName: product.name,
      //   brands: product.brands,
      //   quantity: product.weight,
      // );
      // final offImages = <off.ImageField, File>{
      //   if (_frontImage != null) off.ImageField.FRONT: File(_frontImage!.path),
      //   if (_frontImage != null) off.ImageField.PACKAGING: File(_frontImage!.path),
      //   if (ingredientsImage != null) off.ImageField.INGREDIENTS: File(ingredientsImage!.path),
      //   if (_nutritionImage != null) off.ImageField.NUTRITION: File(_nutritionImage!.path),
      // };
      // await _oFFService.addProduct(product, offImages);
      // ─────────────────────────────────────────────────────────────────────────────────────────

      _showSnackbar(widget.successMessage, Colors.green);
      await widget.onSuccessfulProductAddition?.call(product.ean);
    } catch (e) {
      developer.log("An error occurred while adding a new product...",
          error: e);
      final errorMessage = _formatUserFacingError(e);
      setState(() {
        _errorMessage = errorMessage;
      });
      _showSnackbar(errorMessage, Colors.red);
      widget.onErrorProductAddition?.call(e);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      isWorking = false;
    });
  }

  String _formatUserFacingError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  void _showSnackbar(String text, Color color) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    TextStyle style = const TextStyle(color: Colors.white);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(text, style: style), backgroundColor: color));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Product Details",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: _inputDecoration("Barcode", Icons.qr_code_scanner),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a barcode';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productNameController,
                decoration:
                    _inputDecoration("Product Name", Icons.label_outline),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandController,
                decoration: _inputDecoration(
                    "Brand", Icons.branding_watermark_outlined),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: _inputDecoration(
                    "Quantity and Weight", Icons.scale_outlined),
              ),
              const SizedBox(height: 32),
              Text(
                "Product Images",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCard("Front", _frontImage, 'front'),
                  _buildImageCard(
                      "Ingredients", ingredientsImage, 'ingredients'),
                  _buildImageCard("Nutrition", _nutritionImage, 'nutrition'),
                ],
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Region: $_region')),
                  Chip(label: Text('Language: $_language')),
                ],
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (isWorking)
                Column(
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Submitting to Open Food Facts. This can take a while.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: widget.onCancelProductAddition,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Cancel",
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _addProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: Text(widget.submitButtonLabel,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageType, XFile? image, String tag) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickImage(tag),
        onLongPress: () => _clearImage(tag),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: image == null
                        ? Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            width: 2)
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: image != null
                      ? Image.file(
                          File(image.path),
                          fit: BoxFit.cover,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.6),
                                size: 28),
                            const SizedBox(height: 8),
                            Text("Add",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.8))),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                imageType,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
