import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/constants.dart';

class InoDrawer extends StatefulWidget {
  final Future<void> Function() logout;

  const InoDrawer({Key? key, required this.logout}) : super(key: key);

  @override
  State<InoDrawer> createState() => _InoDrawerState();
}

class _InoDrawerState extends State<InoDrawer> {
  bool forceFetchProducts = Globals.forceFetchProducts;

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Spacer(),
          ),
          ListTile(
            title: Row(
                children: [
                  const Text('Force fetch: '),
                  Checkbox(value: forceFetchProducts, onChanged: (bool? value) {
                    Globals.forceFetchProducts = value!;
                    setState(() {
                      forceFetchProducts = value;
                    });
                  }),
                ]
            ),
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await widget.logout();
              scaffoldMessenger.showSnackBar(const SnackBar(
                  content: Text("Successfully logged out",
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.green));
              navigator.pop();
            },
          )
        ]));
  }
}
