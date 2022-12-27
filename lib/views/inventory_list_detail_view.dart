import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/models/inventory_list_item.dart';
import 'package:inoventory_ui/services/inventory_list/inventory_list_service.dart';
import 'package:inoventory_ui/services/product/product_service_interface.dart';
import 'package:inoventory_ui/services/product/product_service_impl.dart';
import 'package:inoventory_ui/views/product/product_search_view.dart';


import '../services/barcode_scanner.dart';
import '../widgets/expandable_floating_action_button.dart';
import '../widgets/inoventory_appbar.dart';

class InventoryListDetailWidget extends StatefulWidget {
  final InventoryList list;

  const InventoryListDetailWidget({super.key, required this.list});

  @override
  State<InventoryListDetailWidget> createState() =>
      _InventoryListDetailWidgetState();
}

class _InventoryListDetailWidgetState extends State<InventoryListDetailWidget> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final ProductService productService = ProductServiceImpl();
  final InventoryListService listService = Dependencies.inoventoryListService;

  String barcodeScanResult = "";

  late List<InventoryListItem> _items;

  @override
  void initState() {
    super.initState();
   _items = listService.getListItems(widget.list);
  }

  void barcodeScanned(String barcode) {
    setState(() {
      barcodeScanResult = barcode;
    });
  }


  Future<void> _refreshList() async {
    setState(() {
      _items = listService.getListItems(widget.list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: InoventoryAppBar(
        title: widget.list.name,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        child: ListView(
          children: ListTile.divideTiles(
              context: context,
              tiles: _items.map((e) {
                return ListTile(
                  title: Text(e.name, style: const TextStyle(fontSize: 24)),
                  trailing: const Icon(Icons.more_vert),
                  // onTap: () { Navigator.push(context, ) },
                );
              })).toList(),
        ),
      ),
      floatingActionButton: ExpandableFab(distance: 50, children: [
        ActionButton(
          icon: const Icon(Icons.camera_alt, color: Colors.black),
          onPressed: () async {
            final navigator = Navigator.of(context);
            barcodeScanResult = await _barcodeScanner.scanBarcodeNormal();
            navigator.push(
                MaterialPageRoute(
                    builder: (context) => ProductSearchView(initialSearchValue: barcodeScanResult, productService: productService, list: widget.list)));
            }
        ),
        ActionButton(
          icon: const Icon(Icons.edit, color: Colors.black),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProductSearchView(productService: productService, initialSearchValue: "", list: widget.list)
                )
            );
          },
        ),
      ]),
    );
  }

}
