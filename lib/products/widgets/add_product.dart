import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddProductView extends StatefulWidget {
  String barcode;
  AddProductView({Key? key, this.barcode = ""}) : super(key: key);
  @override
  _AddProductViewState createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _labelController = TextEditingController();
  late ImagePicker imagePicker;
  XFile? _frontImage;
  XFile? _backImage;
  XFile? _nutritionImage;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
  }

  Future<void> _pickImage(String imageType) async {
    final image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (imageType == "front") {
          _frontImage = image;
        } else if (imageType == "back") {
          _backImage = image;
        } else {
          _nutritionImage = image;
        }
      });
    }
  }

  Future<void> _addProduct() async {
    // if (_formKey.currentState.validate()) {
    // Perform validation on the input fields
    //...
    // Add the product to a remote server or save it locally
    //...
    print("Product added successfully");
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
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
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: "Label",
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a label';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildImageCard("Front Image", _frontImage, "front"),
          _buildImageCard("Back Image", _backImage, "back"),
          _buildImageCard("Nutrition Image", _nutritionImage, "nutrition"),
          ElevatedButton(
            onPressed: _addProduct,
            child: const Text("Add Product"),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String imageType, XFile? image, String tag) {
    return GestureDetector(
      onTap: () => _pickImage(tag),
      child: Card(
        child: Column(
          children: [
            if (image != null)
              Image.file(
                File(image.path),
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(imageType),
            ),
          ],
        ),
      ),
    );
  }
}
