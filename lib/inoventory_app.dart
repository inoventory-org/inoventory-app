import 'package:flutter/material.dart';
import 'package:inoventory_ui/auth/services/auth_service.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/config/themes.dart';

import 'home_route.dart';

class InoventoryApp extends StatelessWidget {
  final String title;
  final AuthService authService;

  const InoventoryApp(
      {super.key, this.title = "inoventory", required this.authService});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: title,
        theme: Constants.darkMode ? darkTheme : lightTheme, // themeDataLight,
        home: InoventoryHomeRoute(authService: authService));
  }
}
