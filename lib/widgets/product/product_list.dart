import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/views/edit_product_view.dart';
import 'package:inoventory_ui/widgets/product/product_list_item.dart';

class ProductListView extends StatefulWidget {
  final List<Product>? products;
  final void Function(Product product)? onProductTap;
  const ProductListView({Key? key, this.products, this.onProductTap})
      : super(key: key);

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  @override
  Widget build(BuildContext context) {
    if (widget.products == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(child: Text("No results found")),
          const SizedBox(height: 10),
          Center(
              child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.black,
                  child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const EditProductView()));
                      },
                      color: Colors.white,
                      icon: const Icon(Icons.add))))
        ],
      );
    }
    return ListView(
        children: ListTile.divideTiles(
            context: context,
            tiles: widget.products!.map((product) {
              return ProductListItem(
                  product: product,
                  onTap: () {
                    widget.onProductTap!(product);
                  });
            })).toList());
  }
}
