import 'package:flutter/material.dart';
import 'package:inoventory_ui/auth/services/auth_service.dart';
import 'package:inoventory_ui/auth/services/auth_service_mobile.dart'
    if (dart.library.html) 'package:inoventory_ui/auth/services/auth_service_web.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inoventory_app.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // This is needed due to async init;
  configureDependencies();
  AuthService? authService;
  try {
    authService = await AuthServiceImpl.create();
  } catch (e) {
    developer.log("An error occurred while authenticating user. Check your internet connection.", error: e);
  }
  runApp(InoventoryApp(authService: authService));
}
