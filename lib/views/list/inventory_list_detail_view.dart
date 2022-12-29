import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/models/inventory_list_item.dart';
import 'package:inoventory_ui/services/inventory_list_service.dart';
import 'package:inoventory_ui/services/item_service.dart';
import 'package:inoventory_ui/services/product_service.dart';
import 'package:inoventory_ui/views/product/product_search_view.dart';
import 'package:inoventory_ui/widgets/MyFutureBuilder.dart';
import 'package:inoventory_ui/widgets/list/item_list_widget.dart';


import '../../services/barcode_scanner.dart';
import '../../widgets/expandable_floating_action_button.dart';
import '../../widgets/inoventory_appbar.dart';

class InventoryListDetailWidget extends StatefulWidget {
  final InventoryList list;

  const InventoryListDetailWidget({super.key, required this.list});

  @override
  State<InventoryListDetailWidget> createState() =>
      _InventoryListDetailWidgetState();
}

class _InventoryListDetailWidgetState extends State<InventoryListDetailWidget> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final ProductService productService = Dependencies.productService;
  final InventoryListServiceMock listService = InventoryListServiceMock();
  final ItemService itemService = Dependencies.itemService;

  String barcodeScanResult = "";

  late Future<List<InventoryListItem>> futureItems;

  @override
  void initState() {
    super.initState();
   futureItems = itemService.all(widget.list.id);
  }

  void barcodeScanned(String barcode) {
    setState(() {
      barcodeScanResult = barcode;
    });
  }

  void deleteItem(listId, itemId) async {
  itemService.delete(listId, itemId);
  await _refreshList();
}

Future<void> _refreshList() async {
  setState(() {
    futureItems = itemService.all(widget.list.id);
  });
}

  void transitToProductSearchPage(BuildContext context, String? initialSearchValue) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ProductSearchView(productService: productService,
                    initialSearchValue: initialSearchValue,
                    list: widget.list)
        )
    ).then((value) => _refreshList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: InoventoryAppBar(
        title: widget.list.name,
      ),
      body: MyFutureBuilder<List<InventoryListItem>>(
        future: futureItems,
        futureFetcher: () {
          return itemService.all(widget.list.id);
        },
        successBuilder: (context, snapshot) {
          return ItemListWidget(items: snapshot.data ?? [], onDelete: deleteItem);
        },
      ),
      floatingActionButton: ExpandableFab(distance: 50, children: [
        ActionButton(
          icon: const Icon(Icons.camera_alt, color: Colors.black),
          onPressed: () async {
            final navigator = Navigator.of(context);
            barcodeScanResult = await _barcodeScanner.scanBarcodeNormal();
            navigator.push(
                MaterialPageRoute(
                    builder: (context) => ProductSearchView(initialSearchValue: barcodeScanResult,
                        productService: productService,
                        list: widget.list))
            ).then((value) => _refreshList());
            }
        ),
        ActionButton(
          icon: const Icon(Icons.edit, color: Colors.black),
          onPressed: () {
            transitToProductSearchPage(context, "3017620425035");
          },
        ),
      ]),
    );
  }

}
