import 'package:flutter/material.dart';
import 'package:inoventory_ui/routes/login_route.dart';
import 'package:inoventory_ui/widgets/inoventory_appbar.dart';

class InoventoryHomeRoute extends StatelessWidget {
  const InoventoryHomeRoute({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: InoventoryAppBar(),
        drawer: const Drawer(),
        body: const LoginRoute());

        // Center(
        //   child: TextButton(
        //       child: Text(
        //         "My Lists",
        //         style: TextStyle(
        //             fontSize: 40,
        //             color: Theme.of(context).colorScheme.onSurface),
        //       ),
        //       onPressed: () {
        //         Navigator.of(context).push(MaterialPageRoute(
        //             builder: (context) => const InventoryListRoute()));
        //       }),
        // ));
  }
}
