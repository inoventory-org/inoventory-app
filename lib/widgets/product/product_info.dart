import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/product.dart';

class ProductInfo extends StatelessWidget {
  final Product product;
  const ProductInfo({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FittedBox(child: Text(product.name, style: const TextStyle(fontSize: 40))),
          const SizedBox(width: 20), // give it width
          FittedBox(child: Text(product.ean, style: const TextStyle(fontSize: 30))),
        ],
      ),
    );
  }
}
