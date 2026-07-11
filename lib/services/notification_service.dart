import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'shrd_high_importance_channel',
    'SHRD Notifications',
    description:
        'Booking, payment and service notifications.',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    await _initializeLocalNotifications();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Notification permission: '
      '${settings.authorizationStatus}',
    );

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        await _showForegroundNotification(message);
      },
    );

    final token = await getToken();

    debugPrint('FCM TOKEN: $token');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings(
      '@drawable/ic_notification',
    );

    const initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      _channel,
    );
  }

  Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'SHRD';

    final body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        '';

    if (title.isEmpty && body.isEmpty) {
      return;
    }

    final androidDetails =
        AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .remainder(100000),
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (error) {
      debugPrint(
        'Unable to get FCM token: $error',
      );

      return null;
    }
  }
}