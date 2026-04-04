import 'package:flutter/material.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/widgets/add_product.dart';

class EditProductRoute extends StatefulWidget {
  final Product product;
  final Future<void> Function(String barcode)? onSuccessfulProductEdit;

  const EditProductRoute({
    Key? key,
    required this.product,
    this.onSuccessfulProductEdit,
  }) : super(key: key);

  @override
  State<EditProductRoute> createState() => _EditProductRouteState();
}

class _EditProductRouteState extends State<EditProductRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Product")),
      body: AddProductView(
        barcode: widget.product.ean,
        initialProduct: widget.product,
        submitButtonLabel: "Save Changes",
        onCancelProductAddition: () {
          Navigator.of(context).pop();
        },
        onSuccessfulProductAddition: (barcode) async {
          await widget.onSuccessfulProductEdit?.call(barcode);
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}
