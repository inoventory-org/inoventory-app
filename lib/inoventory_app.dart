import 'package:flutter/material.dart';
import 'package:inoventory_ui/auth/services/auth_service.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/config/themes.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_appbar.dart';

import 'home_route.dart';

class InoventoryApp extends StatelessWidget {
  final String title;
  final AuthService? authService;

  const InoventoryApp({super.key, this.title = "inoventory", required this.authService});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: title,
        theme: Constants.darkMode ? darkTheme : lightTheme, // themeDataLight,
        home: authService != null
            ? InoventoryHomeRoute(authService: authService!) // typical home page
            // In case of connection issues the following is shown
            : const Scaffold(
                appBar: InoventoryAppBar(),
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Either you have connection issues or there are problems with the backend."
                        "This app requires a connection to the backend to work."
                        "Please restart the app or try again later."),
                  ),
                )));
  }
}
