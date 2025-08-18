// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/screens/main_screen.dart'; // MainScreen をインポートします
import 'package:garbage_app/models/garbage_collection_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 通知プラグインをインポート

// ✅ ここから2行を追加
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// 通知プラグインのインスタンスをグローバルに定義
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  // Flutterウィジェットバインディングが初期化されていることを確認
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ タイムゾーンの初期化を追加 (重要!)
  tz.initializeTimeZones();

  // Android向けの通知設定
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher'); // アプリのアイコンを使用

  // iOS向けの通知設定
  const DarwinInitializationSettings initializationSettingsDarwin =
  DarwinInitializationSettings(
    requestAlertPermission: true, // アラートの許可を要求
    requestBadgePermission: true, // バッジの許可を要求
    requestSoundPermission: true, // サウンドの許可を要求
  );

  // 全プラットフォーム共通の初期化設定
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  // 通知プラグインの初期化を実行
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    // onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
    //   // 通知をタップしたときの処理（必要に応じて実装）
    // },
    // onDidReceiveBackgroundNotificationResponse: (NotificationResponse notificationResponse) async {
    //   // バックグラウンドでの通知をタップしたときの処理（必要に応じて実装）
    // },
  );

  // Android 13 (API 33) 以降で必要: 通知権限の要求
  final bool? result = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  if (result == true) {
    print("通知権限が付与されました");
  } else {
    print("通知権限が拒否されました");
  }

  runApp(
    // アプリ全体でGarbageCollectionSettingsを提供
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
      title: 'ごみ収集アプリ', // アプリのタイトル
      theme: ThemeData(
        primarySwatch: Colors.blue, // テーマカラー
        useMaterial3: true, // Material 3 デザインを有効に
      ),
      home: const MainScreen(), // ここを MainScreen() に変更
    );
  }
}
