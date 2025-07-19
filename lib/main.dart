// lib/main.dart
import 'package:flutter/material.dart';
import 'package:garbage_app/screens/main_screen.dart';
import 'package:provider/provider.dart'; // Providerを使用するため必要
import 'package:garbage_app/models/garbage_collection_settings.dart'; // 新しく追加

void main() {
  runApp(
    // MultiProvider を使用して複数のProviderを登録
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GarbageCollectionSettings()..loadSettings()), // 初期ロードも行う
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ごみ分別',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}