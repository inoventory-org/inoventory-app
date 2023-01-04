import 'package:flutter/material.dart';
import 'dart:developer' as developer;

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
                      developer.log("Search pressed!");
                    }),
          ],
        );
}
