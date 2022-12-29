import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/services/product_service.dart';
import 'package:inoventory_ui/views/product/product_detail_view.dart';
import 'package:inoventory_ui/widgets/inoventory_search_bar.dart';
import 'package:inoventory_ui/widgets/product/product_list.dart';

class ProductSearchView extends StatefulWidget {
  final String? initialSearchValue;
  final ProductService productService;
  final InventoryList list;

  const ProductSearchView(
      {Key? key, this.initialSearchValue, required this.productService, required this.list})
      : super(key: key);

  @override
  State<ProductSearchView> createState() => _ProductSearchViewState();
}

class _ProductSearchViewState extends State<ProductSearchView> {
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
                    builder: (context) => ProductDetailView(product: product, list: widget.list),
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
