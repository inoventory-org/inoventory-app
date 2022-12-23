
import 'package:flutter/material.dart';
import 'package:inoventory_ui/views/inventory_list_view.dart';
import 'package:inoventory_ui/widgets/inoventory_appbar.dart';

class InoventoryHome extends StatelessWidget {
  const InoventoryHome({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: InoventoryAppBar(),
        drawer: const Drawer(),
        body: const InventoryListWidget()
    );
  }
}
