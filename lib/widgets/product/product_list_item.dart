import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/product.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  final  void Function()? onTap;
  const ProductListItem({Key? key, required this.product, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(product.name, style: const TextStyle(fontSize: 24)),
      trailing: const Icon(Icons.more_vert),
      onTap: onTap,
    );
  }
}
