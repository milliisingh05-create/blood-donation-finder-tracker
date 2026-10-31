import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_collections.dart';

/// Service managing FCM push notifications and native foreground local notification channels.
class PushNotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;

  static const AndroidNotificationChannel _emergencyChannel = AndroidNotificationChannel(
    'emergency_sos_channel',
    'Emergency SOS Alerts',
    description: 'High-priority critical blood requests within active radius',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _generalChannel = AndroidNotificationChannel(
    'general_alerts_channel',
    'General Notifications',
    description: 'Donation eligibility, badges, and request status updates',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  /// Initialize local notification plugins and FCM listeners.
  Future<void> initialize({void Function(String? payload)? onSelectNotification}) async {
    if (_initialized) return;

    // 1. Configure platform-specific initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      if (!kIsWeb) {
        await _localNotifications.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            onSelectNotification?.call(response.payload);
          },
        );

        // Register Android channels
        final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(_emergencyChannel);
          await androidPlugin.createNotificationChannel(_generalChannel);
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[PushNotificationService] Local notifications init error: $e');
      _initialized = true;
    }

    // 2. Initialize Firebase Messaging if Firebase is ready
    if (Firebase.apps.isNotEmpty) {
      await _setupFirebaseMessaging();
    }
  }

  /// Setup Firebase Cloud Messaging permissions, token registration, and background handlers.
  Future<void> _setupFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[PushNotificationService] Permission status: ${settings.authorizationStatus}');

      // Fetch FCM Token
      _fcmToken = await messaging.getToken();
      debugPrint('[PushNotificationService] FCM Token: $_fcmToken');

      // Listen for foreground FCM messages and trigger local notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[PushNotificationService] Foreground message: ${message.notification?.title}');
        final notification = message.notification;
        if (notification != null) {
          final isSos = message.data['type'] == 'sos';
          showLocalNotification(
            title: notification.title ?? 'Blood Donation Alert',
            body: notification.body ?? '',
            payload: message.data['requestId'] ?? message.data['route'],
            isEmergency: isSos,
          );
        }
      });

      // Listen to token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
      });
    } catch (e) {
      debugPrint('[PushNotificationService] FCM setup error: $e');
    }
  }

  /// Register or update user device FCM token in Cloud Firestore.
  Future<void> registerUserDeviceToken(String userId) async {
    if (Firebase.apps.isEmpty || _fcmToken == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(userId)
          .set({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[PushNotificationService] Error saving FCM token for user $userId: $e');
    }
  }

  /// Trigger a local system notification banner.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool isEmergency = false,
  }) async {
    if (kIsWeb) {
      // Web uses browser notifications or in-app snackbars
      debugPrint('[PushNotificationService Web] Local Alert: $title - $body');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      isEmergency ? _emergencyChannel.id : _generalChannel.id,
      isEmergency ? _emergencyChannel.name : _generalChannel.name,
      channelDescription: isEmergency ? _emergencyChannel.description : _generalChannel.description,
      importance: isEmergency ? Importance.max : Importance.defaultImportance,
      priority: isEmergency ? Priority.high : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      final notifId = DateTime.now().millisecondsSinceEpoch % 100000;
      await _localNotifications.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[PushNotificationService] Error showing local notification: $e');
    }
  }
}

/// Global provider for PushNotificationService.
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});
