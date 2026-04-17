import 'dart:convert';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/profile_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/login.dart';
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_details.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:one_context/one_context.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future initialise() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          Map<String, dynamic> data = jsonDecode(response.payload!);
          _handleMessageNavigation(data);
        }
      },
    );

    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    String? fcmToken = await _fcm.getToken();
    if (is_logged_in.$ == true && fcmToken != null) {
      await ProfileRepository().getDeviceTokenUpdateResponse(fcmToken);
    }
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage.data);
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageNavigation(message.data);
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleMessageNavigation(Map<String, dynamic> data) {
    if (is_logged_in.$ == false) {
      _showLoginDialog();
      return;
    }

    if (data['item_type'] == 'order' && data['item_type_id'] != null) {
      try {
        OneContext().push(
          MaterialPageRoute(
            builder: (_) {
              return OrderDetails(
                id: int.parse(data['item_type_id']),
                fromNotification: true,
              );
            },
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          print('print:$e');
        }
      }
    }
  }

  void _showLoginDialog() {
    OneContext().showDialog(
      builder: (context) => AlertDialog(
        title: const Text("You are not logged in"),
        content: const Text("Please log in to see the details"),
        actions: <Widget>[
          Btn.basic(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Btn.basic(
            child: const Text('Login'),
            onPressed: () {
              Navigator.of(context).pop();
              OneContext().push(
                MaterialPageRoute(builder: (_) => const Login()),
              );
            },
          ),
        ],
      ),
    );
  }
}
