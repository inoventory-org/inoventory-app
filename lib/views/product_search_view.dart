import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/services/products/product_service_impl.dart';
import 'package:inoventory_ui/services/products/product_service_interface.dart';
import 'package:inoventory_ui/widgets/inoventory_search_bar.dart';
import 'package:inoventory_ui/widgets/product/product_list.dart';

class ProductSearchView extends StatefulWidget {
  final String? initialValue;

  const ProductSearchView({Key? key, this.initialValue}) : super(key: key);

  @override
  State<ProductSearchView> createState() => _ProductSearchViewState();
}

class _ProductSearchViewState extends State<ProductSearchView> {
  final ProductService productService = ProductServiceImpl();
  late Future<List<Product>> futureProducts;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      futureProducts = productService.search(widget.initialValue ?? "");
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
            initialValue: widget.initialValue, onChanged: onSearchBarChanged),
        body: FutureBuilder<List<Product>>(
            future: futureProducts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData) {
                return ProductListView(products: snapshot.data);
              } else if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              }
              return const Center(child: CircularProgressIndicator());
            }));
  }
}
