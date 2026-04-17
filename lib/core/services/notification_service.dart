import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles both local (in-app) and FCM (background/killed) push notifications.
///
/// Initialization order:
///   1. Firebase.initializeApp()
///   2. NotificationService.instance.init()
///   3. Subscribe to WebSocketService streams to show local notifications
///      when a new message arrives while the app is open.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'ikenas_messages';
  static const _channelName = 'Messages';
  static const _channelDesc = 'Notifications pour les nouveaux messages';

  bool _initialized = false;

  // ── init ──────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // ── Android notification channel ──────────────────────────
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    // Request POST_NOTIFICATIONS permission (Android 13+)
    await androidPlugin?.requestNotificationsPermission();

    // ── iOS / macOS permission ────────────────────────────────
    if (Platform.isIOS) {
      await _local
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // ── Local notifications plugin init ───────────────────────
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // ── Firebase Messaging permissions ────────────────────────
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Show local notification when app is in foreground and FCM arrives
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      final n = msg.notification;
      if (n != null) {
        show(
          title: n.title ?? 'Nouveau message',
          body: n.body ?? '',
        );
      }
    });

    debugPrint('[NotificationService] initialized');
  }

  // ── show ──────────────────────────────────────────────────────
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  // ── FCM token (useful when backend adds FCM support) ──────────
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();
}
