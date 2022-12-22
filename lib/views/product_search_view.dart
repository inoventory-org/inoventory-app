import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/product.dart';
import 'package:inoventory_ui/services/products/product_service_impl.dart';
import 'package:inoventory_ui/services/products/product_service_interface.dart';
import 'package:inoventory_ui/views/edit_product_view.dart';
import 'package:inoventory_ui/widgets/inoventory_search_bar.dart';

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
                    ? ListView(
                        children: ListTile.divideTiles(
                            context: context,
                            tiles: snapshot.data!.map((product) {
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
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const EditProductView()));
                                      },
                                      color: Colors.white,
                                      icon: const Icon(Icons.add))))
                        ],
                      ));
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
