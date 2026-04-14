import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  static NotificationService get instance => _instance;

  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('[Notification] Web platform — push notifications disabled');
      return;
    }
    
    // On mobile, use AwesomeNotifications
    try {
      await AwesomeNotifications().initialize(null, [
        NotificationChannel(
          channelKey: 'trading_channel',
          channelName: 'Trading Signals',
          channelDescription: 'Trade signals and order notifications',
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          defaultColor: const Color(0xFF00E5FF),
          ledColor: const Color(0xFF00E5FF),
          defaultRingtoneType: DefaultRingtoneType.Notification,
        ),
        NotificationChannel(
          channelKey: 'alert_channel',
          channelName: 'Market Alerts',
          channelDescription: 'News and market alerts',
          importance: NotificationImportance.Default,
          channelShowBadge: true,
          enableVibration: true,
          defaultColor: const Color(0xFFFF9100),
          defaultRingtoneType: DefaultRingtoneType.Notification,
        ),
      ]);

      AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onActionReceived,
      );
      debugPrint('[Notification] AwesomeNotifications initialized');
    } catch (e) {
      debugPrint('[Notification] Init error: $e');
    }
  }

  static Future<void> _onActionReceived(ReceivedAction action) async {
    debugPrint('Notification action received: ${action.id}');
  }

  Future<void> ensureNotificationPermission() async {
    if (kIsWeb) return;
    
    var status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> showTradeNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('[NOTIFICATION] $title: $body');
    if (kIsWeb) return;
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          channelKey: 'trading_channel',
          id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
          title: title,
          body: body,
          autoDismissible: true,
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (e) {
      debugPrint('[Notification] Error creating trade notification: $e');
    }
  }

  Future<void> showAlertNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('[ALERT] $title: $body');
    if (kIsWeb) return;
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          channelKey: 'alert_channel',
          id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
          title: title,
          body: body,
          autoDismissible: true,
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (e) {
      debugPrint('[Notification] Error creating alert notification: $e');
    }
  }
}
