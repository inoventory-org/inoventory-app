
import 'package:flutter/material.dart';
import 'package:inoventory_ui/views/home_view.dart';

class InoventoryApp extends StatelessWidget {
  final String title;
  final themeDataLight = ThemeData(
    primaryColor: const Color(0x0000BCD4),
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.cyan).copyWith(secondary: Colors.orange),
    textTheme: const TextTheme(
      headline1: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold, color: Colors.black),
      headline2: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black),
      headline3: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black),
      headline4: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black),
      bodyText1: TextStyle(fontSize: 16.0, color: Colors.black),
      bodyText2: TextStyle(fontSize: 14.0, color: Colors.black),
    ),
  );


  InoventoryApp({super.key, this.title = "inoventory"});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData.dark(), // themeDataLight,
      home: const InoventoryHome()
    );
  }
}
