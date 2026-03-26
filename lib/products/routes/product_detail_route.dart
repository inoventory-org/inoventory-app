import 'package:flutter/material.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/inventory/items/widgets/add_item.dart';
import 'package:inoventory_ui/products/widgets/product_info.dart';
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-image-${widget.product.ean}',
                child: widget.product.imageUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          InoventoryNetworkImage(url: widget.product.imageUrl!),
                          // Elegant subtle gradient overlay for the image when scroll
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black38, Colors.transparent, Colors.white10],
                                stops: [0.0, 0.3, 1.0],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.background,
                        child: Center(
                          child: Icon(Icons.inventory_2_outlined,
                              size: 100,
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2)),
                        ),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 24.0),
                child: ProductInfo(product: widget.product),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add to List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
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
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
