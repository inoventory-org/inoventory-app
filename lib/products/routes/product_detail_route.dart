import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/inventory/items/widgets/add_item.dart';
import 'package:inoventory_ui/products/widgets/product_info.dart';
import 'package:inoventory_ui/shared/widgets/add_to_list_btn.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_appbar.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_network_image.dart';

class ProductDetailRoute extends StatefulWidget {
  final Product product;
  final InventoryList list;

  const ProductDetailRoute(
      {Key? key, required this.product, required this.list})
      : super(key: key);

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
              if (widget.product.imageUrl != null) InoventoryNetworkImage(url: widget.product.imageUrl!),
              ProductInfo(product: widget.product),
              AddToListButton(onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return AddItemView(
                    widget.product,
                    widget.list,
                    postAddCallback: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  );
                }));
                // Navigator.of(context).pop();
              })
            ],
          ),
        ),
      ),
    );
  }
}
