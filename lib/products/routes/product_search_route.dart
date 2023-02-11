import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/products/routes/product_detail_route.dart';
import 'package:inoventory_ui/products/product_service.dart';
import 'package:inoventory_ui/shared/widgets/future_error_retry_widget.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_search_bar.dart';
import 'package:inoventory_ui/products/widgets/product_list.dart';
import 'dart:developer' as developer;

import '../../config/constants.dart';

class ProductSearchRoute extends StatefulWidget {
  final String? initialSearchValue;
  final ProductService productService;
  final InventoryList list;

  const ProductSearchRoute(
      {Key? key,
      this.initialSearchValue,
      required this.productService,
      required this.list})
      : super(key: key);

  @override
  State<ProductSearchRoute> createState() => _ProductSearchRouteState();
}

class _ProductSearchRouteState extends State<ProductSearchRoute> {
  late ProductService productService;
  late Future<List<Product>> futureProducts;

  @override
  void initState() {
    super.initState();
    productService = widget.productService;
    if (widget.initialSearchValue != null) {
      futureProducts = productService.search(widget.initialSearchValue ?? "", fresh: Globals.forceFetchProducts);
    } else {
      futureProducts = productService.all();
    }
  }

  void onSearchBarChanged(String value) {
    setState(() {
      futureProducts = productService.search(value, fresh: Globals.forceFetchProducts);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: InoventorySearchBar(
        initialValue: widget.initialSearchValue,
        onChanged: onSearchBarChanged,
      ),
      body: FutureBuilder<List<Product>>(
        future: futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            if (snapshot.data?.length == 1) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ProductDetailRoute(
                      product: snapshot.data!.first, list: widget.list),
                ));
              });
            }

            return ProductListView(
              products: snapshot.data ?? [],
              onProductTap: (product) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailRoute(product: product, list: widget.list),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            developer.log("An error occurred while retrieving products.",
                error: snapshot.error);
            return FutureErrorRetryWidget(
                onRetry: () {
                  setState(() {});
                },
                child: const Center(
                    child: Text(
                        'An error occurred while retrieving products. Please try again.')));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
