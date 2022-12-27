
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/config/themes.dart';
import 'package:inoventory_ui/views/home_view.dart';

class InoventoryApp extends StatelessWidget {
  final String title;


  const InoventoryApp({super.key, this.title = "inoventory"});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: Constants.darkMode ? darkTheme : lightTheme, // themeDataLight,
      home: const InoventoryHome()
    );
  }
}