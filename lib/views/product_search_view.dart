import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/services/product_service.dart';
import 'package:inoventory_ui/widgets/inoventory_search_bar.dart';

class ProductSearchView extends StatefulWidget {
  final String? initialValue;

  const ProductSearchView({Key? key, this.initialValue}) : super(key: key);

  @override
  State<ProductSearchView> createState() => _ProductSearchViewState();
}

class _ProductSearchViewState extends State<ProductSearchView> {
  final ProductService productService = ProductService();
  late List<Product> _products;
  final String searchQuery = "";

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _products = productService.search(widget.initialValue ?? "");
    } else {
      _products = productService.all();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: InoventorySearchBar(
            initialValue: widget.initialValue,
            onChanged: (value) {
              setState(() {
                _products = productService.search(value);
              });
            }),
        body: (_products.isNotEmpty)
            ? ListView(
                children: ListTile.divideTiles(
                    context: context,
                    tiles: _products.map((product) {
                      return ListTile(
                        title: Text(product.name,
                            style: const TextStyle(fontSize: 24)),
                        trailing: const Icon(Icons.more_vert),
                      );
                    })).toList())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Center(child: Text("No results found")),
                  const SizedBox(height: 10),
                  Center(
                      child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.black,
                          child: IconButton(
                              onPressed: () {
                                print("button pressed!"); // Todo: Navigate to add product page
                              },
                              color: Colors.white,
                              icon: const Icon(Icons.add))))
                ],
              ));
  }
}
