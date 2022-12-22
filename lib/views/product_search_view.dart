import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/services/products/product_service_interface.dart';
import 'package:inoventory_ui/services/products/product_service_mock.dart';
import 'package:inoventory_ui/widgets/inoventory_search_bar.dart';
import 'package:inoventory_ui/widgets/product/product_list.dart';

class ProductSearchView extends StatefulWidget {
  final String? initialValue;

  const ProductSearchView({Key? key, this.initialValue}) : super(key: key);

  @override
  State<ProductSearchView> createState() => _ProductSearchViewState();
}

class _ProductSearchViewState extends State<ProductSearchView> {
  final ProductService productService = ProductServiceMock();
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
            initialValue: widget.initialValue,
            onChanged: onSearchBarChanged
        ),
        body: FutureBuilder<List<Product>>(
            future: futureProducts,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ProductListView(products: snapshot.data);
              } else if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              }

              return const Center(child: CircularProgressIndicator());

            }));

    // return FutureBuilder<List<Product>>(
    //     future: futureProducts,
    //     builder: (context, snapshot) {
    //       if (snapshot.hasData) {
    //         return Scaffold(
    //             appBar: InoventorySearchBar(
    //                 initialValue: widget.initialValue,
    //                 onChanged: (value) => onSearchBarChanged(value)),
    //             body: (snapshot.hasData)
    //                 ? ProductListView(products: snapshot.data) : const Center(child: CircularProgressIndicator())
    //         );
    //       } else if (snapshot.hasError) {
    //         return Text('${snapshot.error}');
    //        } else {
    //         return const Text("failure");
    //       }
    //
    //       //   return Scaffold(
    //       //       appBar: AppBar(title: const Text("Loading")),
    //       //       body: const Center(child: CircularProgressIndicator()));
    //       // }
    //     });
  }
}
