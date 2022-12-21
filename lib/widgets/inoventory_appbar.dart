import 'package:flutter/material.dart';

class InoventoryAppBar extends AppBar {
  InoventoryAppBar(
      {super.key, String title = "inoventory", Function()? onPressedCallback})
      : super(
          title: Text(title),
          actions: [
            IconButton(
                icon: const Icon(Icons.search),
                onPressed: onPressedCallback ??
                    () {
                      print("Search pressed!");
                    }),
          ],
        );
}
