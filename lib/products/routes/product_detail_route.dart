import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list.dart';
import 'package:inoventory_ui/products/widgets/add_product.dart';
import 'package:inoventory_ui/shared/widgets/add_to_list_btn.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_network_image.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_appbar.dart';
import 'package:inoventory_ui/products/widgets/product_info.dart';
import 'package:inoventory_ui/products/product_model.dart';

class ProductDetailRoute extends StatefulWidget {
  final Product product;
  final InventoryList list;

  const ProductDetailRoute({Key? key, required this.product, required this.list
  }) : super(key: key);

  @override
  State<ProductDetailRoute> createState() => _ProductDetailRouteState();
}

class _ProductDetailRouteState extends State<ProductDetailRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: InoventoryAppBar(title: widget.product.name),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              InoventoryNetworkImage(url: widget.product.imageUrl!),
              ProductInfo(product: widget.product),
              AddToListButton(onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return AddProductView(widget.product, widget.list);
                  })
                );
                // Navigator.of(context).pop();
              })
            ],
          ),
        ),
      ),
    );
  }
}

