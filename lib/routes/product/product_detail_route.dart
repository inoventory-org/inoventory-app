import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/widgets/product/add_product.dart';
import 'package:inoventory_ui/widgets/add_to_list_btn.dart';
import 'package:inoventory_ui/widgets/InoventoryNetworkImage.dart';
import 'package:inoventory_ui/widgets/inoventory_appbar.dart';
import 'package:inoventory_ui/widgets/product/product_info.dart';
import 'package:inoventory_ui/models/product.dart';

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

