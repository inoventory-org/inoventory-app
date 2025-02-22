import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../inventory/items/item_list_route.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

abstract class NotificationService {
  Stream<NotificationResponse>? get selectNotificationStream => null;

  Future<void> scheduleNotification();

  Future<void> initialize();
}

@Injectable(as: NotificationService)
class NotificationServiceImpl extends NotificationService {
  NotificationServiceImpl();

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('playstore_icon'),
  );

// Streams are created so that app can respond to notification-related events
  /// since the plugin is initialized in the `main` function
  final StreamController<NotificationResponse> _selectNotificationStream =
      StreamController<NotificationResponse>.broadcast();

  @override
  Stream<NotificationResponse> get selectNotificationStream => _selectNotificationStream.stream;

  static Future<void> onDidReceiveNotification(NotificationResponse notificationResponse) async {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => ItemListRoute(list: InventoryList(1, "Lebensmittel"))));
  }

  @override
  Future<void> scheduleNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        20250301,
        'Products are expiring soon :-(',
        'scheduled body overwritten',
        tz.TZDateTime.now(tz.local).add(Duration(seconds: 5)),
        const NotificationDetails(
            android: AndroidNotificationDetails('full screen channel id', 'full screen channel name',
                channelDescription: 'full screen channel description',
                priority: Priority.defaultPriority,
                importance: Importance.low,
                fullScreenIntent: false,
                tag: "list1",
            ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
        payload: "1",
    );


    var pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    developer.log(pendingNotificationRequests.toString());

    await flutterLocalNotificationsPlugin.cancel(20250301);
  }

  @override
  Future<void> initialize() async {
    await _requestPermissions();

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _selectNotificationStream.add,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification,
    );

    tz.initializeTimeZones();
    tz.setLocalLocation(
      tz.getLocation("Europe/Berlin" // TODO: use dynamic timezone from device
          ),
    );
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission = await androidImplementation?.requestExactAlarmsPermission();
      developer.log("Request exact alarm: $grantedNotificationPermission");
    }
  }
}

// void handleBackgroundNotification(NotificationResponse details) {
//   print('Received background notification: ${details.payload}');
// }

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print('notification action tapped with input: ${notificationResponse.input}');
  }
}
