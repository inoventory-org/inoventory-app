import 'package:flutter/material.dart';
import 'package:inoventory_ui/routes/list/inventory_list_route.dart';
import 'package:inoventory_ui/widgets/ContainerWithBoxDecoration.dart';
import 'package:inoventory_ui/widgets/inoventory_appbar.dart';

class InoventoryHomeRoute extends StatelessWidget {
  const InoventoryHomeRoute({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: InoventoryAppBar(),
        drawer: const Drawer(),
        body: TextButton(
              child: Center(
                  child: ContainerWithBoxDecoration(
                      boxColor: Theme.of(context).colorScheme.primary,
                    child: Text("My Lists",
                        style: TextStyle(
                            fontSize: 40,
                            color: Theme.of(context).colorScheme.onSurface)),
                  )),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const InventoryListRoute()));
              }),
        );
  }
}
