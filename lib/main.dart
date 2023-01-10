import 'package:flutter/material.dart';
import 'package:inoventory_ui/auth/services/auth_service.dart';
import 'package:inoventory_ui/auth/services/auth_service_mobile.dart'
    if (dart.library.html) 'package:inoventory_ui/auth/services/auth_service_web.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inoventory_app.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // This is needed due to async init;
  configureDependencies();
  AuthService authService = await AuthServiceImpl.create();
  runApp(InoventoryApp(authService: authService));
}
