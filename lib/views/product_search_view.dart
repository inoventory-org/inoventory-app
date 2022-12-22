import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/services/products/product_service_impl.dart';
import 'package:inoventory_ui/services/products/product_service_interface.dart';
import 'package:inoventory_ui/views/edit_product_view.dart';
import 'package:inoventory_ui/widgets/inoventory_search_bar.dart';
import 'package:inoventory_ui/widgets/product/no_products_found.dart';
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
  final String searchQuery = "";

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      futureProducts = productService.search(widget.initialValue ?? "");
    } else {
      futureProducts = productService.all();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
        future: futureProducts,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
                appBar: InoventorySearchBar(
                    initialValue: widget.initialValue,
                    onChanged: (value) {
                      setState(() {
                        futureProducts = productService.search(value);
                      });
                    }),
                body: (snapshot.hasData)
                    ? ProductListView(products: snapshot.data)
                    : const NoProductsFound(nextWidget: EditProductView()));
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          } else {
            return Scaffold(
                appBar: AppBar(title: const Text("Loading")),
                body: const Center(child: CircularProgressIndicator()));
          }
        });
  }
}
