// lib/main.dart
import 'package:flutter/material.dart';
import 'package:garbage_app/screens/main_screen.dart';
import 'package:garbage_app/providers/user_data_provider.dart';
import 'package:garbage_app/state/game_state.dart'; // ★GameStateのインポート★
import 'package:provider/provider.dart';

void main() {
  runApp(
    // ★修正: MultiProviderを使用して複数のプロバイダを登録★
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserDataProvider()),
        ChangeNotifierProvider(create: (context) => GameState()), // ★GameStateを登録★
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
      title: 'ごみ分別モンスターズ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}