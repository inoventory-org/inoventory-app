import 'package:flutter/material.dart';

class InoventorySearchBar extends AppBar {
  InoventorySearchBar(
      {super.key, String label = "Search", String? initialValue, void Function(String)? onChanged})
      : super(
          title: TextFormField(
            initialValue: initialValue,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: label,
            ),
            onChanged: onChanged
          ),
        );
}
