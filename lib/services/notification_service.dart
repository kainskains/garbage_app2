// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:garbage_app/models/garbage_collection_settings.dart';
import 'package:provider/provider.dart';

// グローバルナビゲーターキーへの参照用
late GlobalKey<NavigatorState> _navigatorKey;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // ナビゲーターキーを設定
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // 初期化
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/launcher_icon');

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

  // 通知権限のリクエスト
  Future<bool> requestPermissions() async {
    // Android 13+ 用の権限リクエスト
    if (Theme.of(_navigatorKey.currentContext!).platform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        try {
          final bool? granted = await androidImplementation.requestNotificationsPermission();
          debugPrint('Android notification permission: $granted');
          return granted ?? false;
        } catch (e) {
          debugPrint('Error requesting Android notification permission: $e');
          return true; // フォールバック
        }
      }
    }

    // iOS用の権限リクエスト - DarwinFlutterLocalNotificationsPlugin → IOSFlutterLocalNotificationsPlugin
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
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
        return true; // フォールバック
      }
    }

    return true;
  }

  // 通知をスケジュール
  Future<void> _scheduleNotificationForType(
      GarbageCollectionSettings provider, String typeId) async {
    final nextCollection = provider.calculateNextCollectionDateTime(typeId);
    if (nextCollection == null) return;

    final notificationTime = nextCollection.subtract(
        Duration(minutes: provider.minutesBeforeNotification!));

    if (notificationTime.isBefore(DateTime.now())) return;

    final garbageTypeName = provider.getGarbageTypeName(typeId);
    final collectionTimeStr =
        '${nextCollection.hour.toString().padLeft(2, '0')}:${nextCollection.minute.toString().padLeft(2, '0')}';

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        typeId.hashCode,
        'ゴミ収集のお知らせ',
        '$garbageTypeName の収集時間（$collectionTimeStr）が近づいています',
        tz.TZDateTime.from(notificationTime, tz.local),
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
      );

      debugPrint('Scheduled notification for $garbageTypeName at $notificationTime');
    } catch (e) {
      debugPrint('Error scheduling notification for $typeId: $e');
    }
  }

  // 全ての通知をスケジュール
  Future<void> scheduleAllNotifications() async {
    try {
      await cancelAllNotifications();

      final context = _navigatorKey.currentContext;
      if (context == null) return;

      final provider = Provider.of<GarbageCollectionSettings>(context, listen: false);

      if (!provider.isNotificationEnabled || provider.minutesBeforeNotification == null) {
        return;
      }

      for (final garbageType in provider.garbageTypes) {
        await _scheduleNotificationForType(provider, garbageType.type);
      }
    } catch (e) {
      debugPrint('Error scheduling all notifications: $e');
    }
  }

  // 全ての通知をキャンセル
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  // 特定のゴミタイプの通知をキャンセル
  Future<void> cancelNotificationForType(String typeId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(typeId.hashCode);
      debugPrint('Cancelled notification for $typeId');
    } catch (e) {
      debugPrint('Error cancelling notification for $typeId: $e');
    }
  }

  // テスト通知を表示
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

  // 今日の通知対象を取得
  Future<List<String>> getTodayNotifications() async {
    try {
      final context = _navigatorKey.currentContext;
      if (context == null) return [];

      final provider = Provider.of<GarbageCollectionSettings>(context, listen: false);
      final today = DateTime.now();
      final todayNotifications = <String>[];

      for (final garbageType in provider.garbageTypes) {
        final nextCollection = provider.calculateNextCollectionDateTime(garbageType.type);
        if (nextCollection != null &&
            nextCollection.year == today.year &&
            nextCollection.month == today.month &&
            nextCollection.day == today.day) {
          todayNotifications.add(garbageType.name);
        }
      }

      return todayNotifications;
    } catch (e) {
      debugPrint('Error getting today notifications: $e');
      return [];
    }
  }

  // 明日の通知対象を取得
  Future<List<String>> getTomorrowNotifications() async {
    try {
      final context = _navigatorKey.currentContext;
      if (context == null) return [];

      final provider = Provider.of<GarbageCollectionSettings>(context, listen: false);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowNotifications = <String>[];

      for (final garbageType in provider.garbageTypes) {
        final nextCollection = provider.calculateNextCollectionDateTime(garbageType.type);
        if (nextCollection != null &&
            nextCollection.year == tomorrow.year &&
            nextCollection.month == tomorrow.month &&
            nextCollection.day == tomorrow.day) {
          tomorrowNotifications.add(garbageType.name);
        }
      }

      return tomorrowNotifications;
    } catch (e) {
      debugPrint('Error getting tomorrow notifications: $e');
      return [];
    }
  }

  // 定期的な通知の再スケジュール
  Future<void> rescheduleNotifications() async {
    debugPrint('Rescheduling notifications...');
    await scheduleAllNotifications();
  }
}

// グローバルナビゲーターキーはmain.dartで定義され、setNavigatorKeyで設定されます