import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/config/secrets.dart';
import 'package:inoventory_ui/inoventory_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // This is needed due to async init;
  configureDependencies();

  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    developer.log("No .env file found, continuing without dotenv.", error: e);
  }
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
  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabasePublishableKey,
  );
  runApp(const InoventoryApp());
}
