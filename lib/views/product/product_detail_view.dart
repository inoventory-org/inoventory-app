import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/widgets/product/add_product.dart';
import '../../widgets/add_to_list_btn.dart';
import '../../widgets/InoventoryNetworkImage.dart';
import '../../widgets/inoventory_appbar.dart';
import '../../widgets/product/product_info.dart';
import '../../models/product.dart';

class ProductDetailView extends StatefulWidget {
  final Product product;
  final InventoryList list;

  const ProductDetailView({Key? key, required this.product, required this.list
  }) : super(key: key);

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
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
                print("Add ${widget.product.name} to list that was used to access this view. The list context is needed.");
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

