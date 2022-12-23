import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/product.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  final void Function()? onTap;
  const ProductListItem({Key? key, required this.product, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.all(5),
        child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).backgroundColor,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 4,
                    color: Color(0x320E151B),
                    offset: Offset(0, 1),
                  )
                ], borderRadius: BorderRadius.circular(12)),
            child: Text(product.name, style: const TextStyle(fontSize: 24))),
      ),
      trailing: const Icon(Icons.more_vert),
      onTap: onTap,
    );
  }
}
