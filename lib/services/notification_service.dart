// lib/services/notification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:garbage_app/models/garbage_collection_settings.dart';
import 'package:provider/provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static late GlobalKey<NavigatorState> _navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
  }

  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation =
      _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        try {
          final bool? granted =
          await androidImplementation.requestNotificationsPermission();
          debugPrint('Android notification permission: $granted');
          return granted ?? false;
        } catch (e) {
          debugPrint('Error requesting Android notification permission: $e');
          return true;
        }
      }
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation =
      _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        try {
          final bool? granted = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('iOS notification permission: $granted');
          return granted ?? false;
        } catch (e) {
          debugPrint('Error requesting iOS notification permission: $e');
          return true;
        }
      }
    }

    return true;
  }

  Future<void> _scheduleNotificationForType(
      GarbageCollectionSettings provider, String typeId) async {
    final nextCollection = provider.calculateNextCollectionDateTime(typeId);
    if (nextCollection == null) return;

    // 通知時間を JST に合わせる
    final notificationTime = nextCollection.subtract(
      Duration(minutes: provider.minutesBeforeNotification ?? 0),
    );

    final now = tz.TZDateTime.now(tz.local);
    if (notificationTime.isBefore(now)) {
      debugPrint('Notification time is in the past, skipping...');
      return;
    }

    final garbageTypeName = provider.getGarbageTypeName(typeId);
    final collectionTimeStr =
        '${nextCollection.hour.toString().padLeft(2, '0')}:${nextCollection.minute.toString().padLeft(2, '0')}';

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        typeId.hashCode,
        'ゴミ収集のお知らせ',
        '$garbageTypeName の収集時間（$collectionTimeStr）が近づいています',
        notificationTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'garbage_collection',
            'ゴミ収集通知',
            channelDescription: 'ゴミ収集日の通知',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: typeId,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
      );

      // JSTでの表示に修正
      final jstTime = tz.TZDateTime.from(notificationTime, tz.local);
      debugPrint('Scheduled notification for $garbageTypeName at $jstTime (JST)');
    } catch (e) {
      debugPrint('Error scheduling notification for $typeId: $e');
    }
  }

  Future<void> scheduleAllNotifications([GarbageCollectionSettings? provider]) async {
    try {
      final context = _navigatorKey.currentContext;
      final settingsProvider = provider ??
          (context != null
              ? Provider.of<GarbageCollectionSettings>(context, listen: false)
              : null);
      if (settingsProvider == null) return;

      await cancelAllNotifications();

      if (!settingsProvider.isNotificationEnabled ||
          settingsProvider.minutesBeforeNotification == null) {
        return;
      }

      for (final garbageType in settingsProvider.garbageTypes) {
        await _scheduleNotificationForType(settingsProvider, garbageType.type);
      }
    } catch (e) {
      debugPrint('Error scheduling all notifications: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  Future<void> cancelNotificationForType(String typeId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(typeId.hashCode);
      debugPrint('Cancelled notification for $typeId');
    } catch (e) {
      debugPrint('Error cancelling notification for $typeId: $e');
    }
  }

  Future<void> showTestNotification() async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        9999,
        'テスト通知',
        'これはテスト通知です。通知が正常に動作しています。',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'テスト通知',
            channelDescription: 'アプリのテスト通知',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }

  Future<void> rescheduleNotifications([GarbageCollectionSettings? provider]) async {
    debugPrint('Rescheduling notifications...');
    await scheduleAllNotifications(provider);
  }
}
