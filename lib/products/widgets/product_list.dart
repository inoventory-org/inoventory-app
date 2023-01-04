import 'package:flutter/material.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/routes/edit_product_route.dart';
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
      return const CentralizedElementWithPlusButton(nextWidget: EditProductRoute());
    }
    return ListView(
        children: ListTile.divideTiles(
            context: context,
            tiles: widget.products.map((product) {
              return ProductListItem(
                  product: product,
                  onTap: () {
                    widget.onProductTap?.call(product);
                  });
            })).toList());
  }
}
