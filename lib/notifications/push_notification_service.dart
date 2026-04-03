import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/constants.dart';

class PushNotificationService {
  static const backendUrl = Constants.inoventoryBackendUrl;
  static const fcmTokenUrl = "$backendUrl/api/v1/user/fcm-token";

  final Dio _dio;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // The UI will set this callback so the service doesn't need to know about Flutter routing
  Function(String listId)? onListNotificationTapped;

  PushNotificationService(this._dio);

  Future<void> initialize() async {
    // Request permissions from the user
    await _fcm.requestPermission(provisional: true);

    // Listen for token refreshes (in case Google rotates the device token)
    _fcm.onTokenRefresh.listen(_syncTokenToBackend);

    // Setup the listeners for incoming messages and taps
    _setupMessageHandlers();
  }

  /// Called manually when a user logs in to ensure the backend has their current token
  Future<void> syncFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _syncTokenToBackend(token);
      }
    } catch (e) {
      developer.log('Failed to get FCM token', error: e);
    }
  }

  Future<void> _syncTokenToBackend(String token) async {
    try {
      await _dio.post(fcmTokenUrl, data: {'token': token});
      developer.log("Successfully synced FCM token to backend.");
    } catch (e) {
      developer.log('Failed to save FCM token to backend', error: e);
    }
  }

  void _setupMessageHandlers() {
    // A. App is open in the FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Received foreground message: ${message.notification?.title}');
      // Note: If you want an in-app banner to appear while the app is open, 
      // you would trigger a local notification or a global Snackbar here.
    });

    // B. App is in BACKGROUND and user taps the notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // C. App is TERMINATED (completely closed) and user taps the notification
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        // A slight delay ensures the Flutter widget tree is fully built before we try to navigate
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(message);
        });
      }
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Extract the listId that backend attached via .putData("listId", ...)
    if (message.data.containsKey('listId')) {
      final listId = message.data['listId'];
      
      if (onListNotificationTapped != null) {
         onListNotificationTapped!(listId);
      } else {
         developer.log("Warning: Notification tapped, but no navigation callback was registered by the UI.");
      }
    }
  }
}