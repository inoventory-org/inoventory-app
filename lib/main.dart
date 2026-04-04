import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/injection.dart';
import 'package:inoventory_ui/config/secrets.dart';
import 'package:inoventory_ui/inoventory_app.dart';
import 'package:inoventory_ui/notifications/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// This must be a top-level function (outside of any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // This is needed due to async init;
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

  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabasePublishableKey,
  );
  runApp(const InoventoryApp());
}
