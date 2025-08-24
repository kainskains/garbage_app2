// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/screens/main_screen.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:garbage_app/services/address_service.dart';
import 'package:garbage_app/services/trash_recognition_service.dart';
import 'package:garbage_app/services/notification_service.dart';

// グローバルナビゲーターキー（通知サービス用）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // タイムゾーンデータを初期化
  tz.initializeTimeZones();

  // 日本時間をローカルタイムゾーンとして設定
  final tokyo = tz.getLocation('Asia/Tokyo');
  tz.setLocalLocation(tokyo);

  // 通知サービスに navigatorKey をセット
  NotificationService.setNavigatorKey(navigatorKey);

  // 通知サービスを初期化
  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  // 既存のサービスを初期化
  await AddressService.loadAddresses();
  await TrashRecognitionService.loadModel();

  runApp(
    ChangeNotifierProvider(
      create: (_) => GarbageCollectionSettings(),
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
      navigatorKey: navigatorKey, // グローバルナビゲーターキー
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreenWithNotifications(),
    );
  }
}

class MainScreenWithNotifications extends StatefulWidget {
  const MainScreenWithNotifications({super.key});

  @override
  State<MainScreenWithNotifications> createState() =>
      _MainScreenWithNotificationsState();
}

class _MainScreenWithNotificationsState
    extends State<MainScreenWithNotifications> with WidgetsBindingObserver {
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
