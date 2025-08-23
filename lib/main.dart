// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/screens/main_screen.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:garbage_app/services/address_service.dart';
import 'package:garbage_app/services/trash_recognition_service.dart';
import 'package:garbage_app/services/notification_service.dart'; // ✅ 追加

// グローバルナビゲーターキー（通知サービス用）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // タイムゾーンデータを初期化
  tz.initializeTimeZones();

  // 通知サービスを初期化
  await NotificationService().initialize();

  // ナビゲーターキーを設定
  NotificationService.setNavigatorKey(navigatorKey);

  // 既存の通知設定（互換性のため残しておく）
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/launcher_icon');

  const DarwinInitializationSettings initializationSettingsDarwin =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      print('Notification selected: ${response.payload}');
    },
  );

  // 通知権限をリクエスト（最新版対応）
  try {
    // iOS用の権限リクエスト - DarwinFlutterLocalNotificationsPlugin → IOSFlutterLocalNotificationsPlugin
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final bool? result = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (result == true) {
        print("通知権限が付与されました");
      } else {
        print("通知権限が拒否されました");
      }
    }

    // Android用の権限リクエスト
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? result = await androidImplementation.requestNotificationsPermission();
      print("Android通知権限: $result");
    }
  } catch (e) {
    print("通知権限リクエストでエラー: $e");
    // 権限リクエストが失敗しても続行
  }

  // 既存のサービスを初期化
  await AddressService.loadAddresses();
  await TrashRecognitionService.loadModel();

  runApp(
    ChangeNotifierProvider(
      create: (context) => GarbageCollectionSettings(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ごみ収集アプリ',
      navigatorKey: navigatorKey, // ✅ グローバルナビゲーターキーを追加
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreenWithNotifications extends StatefulWidget {
  const MainScreenWithNotifications({super.key});

  @override
  State<MainScreenWithNotifications> createState() => _MainScreenWithNotificationsState();
}

class _MainScreenWithNotificationsState extends State<MainScreenWithNotifications>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // アプリ起動時に通知を再スケジュール
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().rescheduleNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // アプリがフォアグラウンドに戻った時に通知を再スケジュール
    if (state == AppLifecycleState.resumed) {
      NotificationService().rescheduleNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}