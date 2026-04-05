import 'package:flutter/material.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/widgets/no_products_found.dart';
import 'package:inoventory_ui/products/widgets/product_list_item.dart';

class ProductListView extends StatefulWidget {
  final List<Product> products;
  final void Function(Product product)? onProductTap;
  const ProductListView({Key? key, required this.products, this.onProductTap})
      : super(key: key);

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const CentralizedElementWithPlusButton();
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12.0, bottom: 80.0),
      itemCount: widget.products.length,
      itemBuilder: (context, index) {
        final product = widget.products[index];
        return ProductListItem(
          product: product,
          onTap: () {
            widget.onProductTap?.call(product);
          },
        );
      },
    );
  }
}
