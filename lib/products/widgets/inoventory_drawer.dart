import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/settings/off_settings_route.dart';

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
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Hi, User!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      ListTile(
        title: Row(children: [
          const Text('Force fetch: '),
          Checkbox(
              value: forceFetchProducts,
              onChanged: (bool? value) {
                Globals.forceFetchProducts = value!;
                setState(() {
                  forceFetchProducts = value;
                });
              }),
        ]),
      ),
      ListTile(
        title: const Text('Open Food Facts Settings'),
        onTap: () async {
          final navigator = Navigator.of(context);
          await navigator.push(
            MaterialPageRoute(
              builder: (context) => const OffSettingsRoute(),
            ),
          );
          if (!mounted) {
            return;
          }
          navigator.pop();
        },
      ),
      ListTile(
        title: const Text('Logout'),
        onTap: () async {
          final navigator = Navigator.of(context);
          navigator.pop();
          await widget.logout();
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Successfully logged out",
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green));
        },
      )
    ]));
  }
}
