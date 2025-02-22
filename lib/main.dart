import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:inoventory_ui/auth/services/auth_service.dart';
import 'package:inoventory_ui/auth/services/auth_service_mobile.dart'
    if (dart.library.html) 'package:inoventory_ui/auth/services/auth_service_web.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/inoventory_app.dart';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_service.dart';
import 'package:inoventory_ui/notifications/notification_service.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // This is needed due to async init;
  configureDependencies();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // You may set the permission requests to "provisional" which allows the user to choose what type
// of notifications they would like to receive once the user receives a notification.
  final notificationSettings = await FirebaseMessaging.instance.requestPermission(provisional: true);

  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    developer.log("fcmToken: $fcmToken");
  }

  final InventoryListService listService = getIt<InventoryListService>();


  final NotificationService notificationService = getIt<NotificationService>();

  await notificationService.initialize();

  notificationService.selectNotificationStream?.listen((NotificationResponse response) async {
    // Handle the notification response here, e.g., navigate to a specific screen
    if (response.payload != null) {
      print("Notification tapped (foreground) with payload: ${response.payload}");
      // Perform navigation or any other action based on the payload
      await listService.get(99);
    }
  });

  await notificationService.scheduleNotification();

  AuthService? authService;
  try {
    authService = await AuthServiceImpl.create();
  } catch (e) {
    developer.log("An error occurred while authenticating user. Check your internet connection.", error: e);
  }
  runApp(InoventoryApp(authService: authService));
}
