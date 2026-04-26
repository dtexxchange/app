import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late final FirebaseMessaging _messaging;
  late final FlutterLocalNotificationsPlugin _localNotifications;
  final ApiService _apiService = ApiService();

  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('Skipping FCM initialization on Web');
      return;
    }
    try {
      _messaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();
      await Firebase.initializeApp();
      
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        sound: true,
        badge: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Admin granted notification permission');
      }

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      );

      await _localNotifications.initialize(initSettings);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Admin foreground message received');
        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await updateDeviceToken();
    } catch (e) {
      debugPrint('Failed to initialize Admin NotificationService: $e');
    }
  }

  Future<void> updateDeviceToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('Admin FCM Token: $token');
        await _apiService.postRequest('/notifications/device-token', {
          'token': token,
          'platform': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'unknown',
        });
      }
    } catch (e) {
      debugPrint('Error uploading admin FCM token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'admin_high_importance_channel',
      'Admin Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Admin background FCM processed');
}
