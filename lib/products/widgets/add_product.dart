import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/products/open_food_facts_service.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;

class AddProductView extends StatefulWidget {
  String barcode;
  void Function() onCancelProductAddition;
  void Function(String barcode)? onSuccessfulProductAddition;
  void Function(Object e)? onErrorProductAddition;

  AddProductView({super.key, this.barcode = "", required this.onCancelProductAddition, this.onSuccessfulProductAddition, this.onErrorProductAddition});

  @override
  _AddProductViewState createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  final OpenFoodFactsService _oFFService = getIt<OpenFoodFactsService>();
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

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    _barcodeController.text = widget.barcode;
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final image = await imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          if (imageType == off.ImageField.NUTRITION.toString()) {
            _nutritionImage = image;
          } else if (imageType == off.ImageField.INGREDIENTS.toString()) {
            ingredientsImage = image;
          } else {
            _frontImage = image;
          }
        });
        _showSnackbar("Long press on the added image to clear it", Colors.green);
      }
    } catch (error) {
      developer.log("error: $error");
    }
  }

  Future<void> _clearImage(String imageType) async {
    setState(() {
      if (imageType == off.ImageField.FRONT.toString()) {
        _frontImage = null;
      } else if (imageType == off.ImageField.INGREDIENTS.toString()) {
        ingredientsImage = null;
      } else {
        _nutritionImage = null;
      }
    });
  }

  Future<void> _addProduct() async {
    Product product = Product(_barcodeController.text, _productNameController.text, ean: _barcodeController.text, brands: _brandController.text, weight: _weightController.text);

    Map<off.ImageField, File> images = {
      if (_frontImage != null) off.ImageField.FRONT: File(_frontImage!.path),
      if (ingredientsImage != null) off.ImageField.INGREDIENTS: File(ingredientsImage!.path),
      if (_nutritionImage != null) off.ImageField.NUTRITION: File(_nutritionImage!.path),
    };

    try {
      setState(() {
        isWorking = true;
      });
      await _oFFService.addProduct(product, images);
      // developer.log("newProduct: $newProduct");
      _showSnackbar("Product added successfully", Colors.green);
      widget.onSuccessfulProductAddition?.call(product.ean);
    } catch (e) {
      developer.log("An error occurred while adding a new product...", error: e);
      _showSnackbar("An error occurred while adding a new product", Colors.red);
      widget.onErrorProductAddition?.call(e);
    }
    setState(() {
      isWorking = false;
    });
  }

  void _showSnackbar(String text, Color color) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    TextStyle style = const TextStyle(color: Colors.white);
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(text, style: style), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: "Barcode",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a barcode';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: "Brand",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a brand';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: "Quantity and Weight",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity or weight';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                child: Row(
                  children: [
                    _buildImageCard("Front Image", _frontImage, off.ImageField.FRONT.toString()),
                    _buildImageCard("Ingredients Image", ingredientsImage, off.ImageField.INGREDIENTS.toString()),
                    _buildImageCard("Nutrition Image", _nutritionImage, off.ImageField.NUTRITION.toString()),
                  ],
                ),
              ),
              if (isWorking) const Center(child: CircularProgressIndicator()),
              ElevatedButton(
                onPressed: _addProduct,
                child: const Text("Add Product"),
              ),
              ElevatedButton(
                onPressed: widget.onCancelProductAddition,
                child: const Text("Cancel"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageType, XFile? image, String tag) {
    const double height = 84;
    const double width = 100;

    return Expanded(
      child: GestureDetector(
        onTap: () => _pickImage(tag),
        onLongPress: () => _clearImage(tag),
        child: Card(
          child: Column(
            children: [
              image != null
                  ? Image.file(
                      File(image.path),
                      height: height,
                      width: width,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox(
                      height: height,
                      width: width,
                      child: Icon(Icons.camera_alt),
                    ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(imageType),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
