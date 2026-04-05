import 'package:flutter/material.dart';
import 'package:inoventory_ui/products/widgets/add_product.dart';

class AddProductRoute extends StatelessWidget {
  final String barcode;
  final Future<void> Function(String barcode)? onSuccessfulProductAddition;

  const AddProductRoute({
    super.key,
    required this.barcode,
    this.onSuccessfulProductAddition,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: AddProductView(
        barcode: barcode,
        onCancelProductAddition: () {
          Navigator.of(context).pop();
        },
        onSuccessfulProductAddition: (submittedBarcode) async {
          await onSuccessfulProductAddition?.call(submittedBarcode);
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}
