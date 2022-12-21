import 'package:flutter/material.dart';
import 'package:inoventory_ui/models/inventory_list.dart';
import 'package:inoventory_ui/models/inventory_list_item.dart';

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

  final List<InventoryListItem> _items = <InventoryListItem>[
    InventoryListItem("id", "myItem")
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: InoventoryAppBar(
        title: widget.list.name,
      ),
      body: ListView(
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
      floatingActionButton: ExpandableFab(distance: 50, children: [
        ActionButton(
          icon: const Icon(Icons.camera_alt, color: Colors.black),
          onPressed: () {
             _barcodeScanner.scanBarcodeNormal();
            // Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => const EanScannerWidget()));
          },
        ),
        const ActionButton(
          icon: Icon(Icons.edit, color: Colors.black),
        )
      ]),
    );
  }
}
