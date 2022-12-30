import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/routes/product/product_detail_route.dart';
import 'package:inoventory_ui/services/product_service.dart';
import 'package:inoventory_ui/widgets/inoventory_search_bar.dart';
import 'package:inoventory_ui/widgets/product/product_list.dart';

class ProductSearchRoute extends StatefulWidget {
  final String? initialSearchValue;
  final ProductService productService;
  final InventoryList list;

  const ProductSearchRoute(
      {Key? key, this.initialSearchValue, required this.productService, required this.list})
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
      futureProducts = productService.search(widget.initialSearchValue ?? "");
    } else {
      futureProducts = productService.all();
    }
  }

  void onSearchBarChanged(String value) {
    setState(() {
      futureProducts = productService.search(value);
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
            return ProductListView(
              products: snapshot.data,
              onProductTap: (product) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductDetailRoute(product: product, list: widget.list),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
