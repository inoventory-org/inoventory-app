import 'package:flutter/material.dart';
import 'package:inoventory_ui/products/product_model.dart';

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
          const SizedBox(width: 20),
          if (product.brands != null && product.brands != "") FittedBox(child: Text(product.brands!, style: const TextStyle(fontSize: 30))),
          const SizedBox(width: 20),
          FittedBox(child: Text(product.ean, style: const TextStyle(fontSize: 25))),
          const SizedBox(width: 20),
          if (product.tags != null && product.tags!.isNotEmpty)
            ExpansionTile(title: const Text("Tags", style: TextStyle(fontSize: 20)),
                children: [
              for (String tag in product.tags!)
                Text(tag, style: const TextStyle(fontSize: 15)),
            ]),
        ],
      ),
    );
  }
}
