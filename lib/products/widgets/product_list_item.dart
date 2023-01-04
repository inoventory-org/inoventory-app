import 'package:flutter/material.dart';
import 'package:inoventory_ui/products/product_model.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  final void Function()? onTap;
  const ProductListItem({Key? key, required this.product, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                image: product.thumbUrl != null
                    ? DecorationImage(
                        image: NetworkImage(product.thumbUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.thumbUrl == null ? const Icon(Icons.image) : null,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 5),
                Text(product.ean, style: const TextStyle(fontSize: 16)),
              ],
            ),
            trailing: const Icon(Icons.more_vert),
            onTap: onTap,
          )),
    );
  }
}
