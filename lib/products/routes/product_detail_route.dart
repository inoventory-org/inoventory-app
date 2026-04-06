import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/expiry_scan/controllers/expiry_scan_controller.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/inventory/items/widgets/add_item.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/products/routes/edit_product_route.dart';
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
  final ProductService _productService = getIt<ProductService>();
  late Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _refreshProduct(String barcode) async {
    final products = await _productService.search(barcode, fresh: true);
    if (!mounted || products.isEmpty) {
      return;
    }
    setState(() {
      _product = products.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            stretch: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Product',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditProductRoute(
                        product: _product,
                        onSuccessfulProductEdit: _refreshProduct,
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-image-${_product.ean}',
                child: _product.imageUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          InoventoryNetworkImage(url: _product.imageUrl!),
                          // Elegant subtle gradient overlay for the image when scroll
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black38,
                                  Colors.transparent,
                                  Colors.white10
                                ],
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.2)),
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
                child: ProductInfo(product: _product),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add to List',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return AddItemView(
              _product,
              widget.list,
              expiryScanController: ExpiryScanController(),
              onDismiss: () {
                Navigator.of(context).pop();
              },
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
