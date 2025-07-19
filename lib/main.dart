// lib/main.dart
import 'package:flutter/material.dart';
import 'package:garbage_app/screens/main_screen.dart';
// import 'package:garbage_app/providers/user_data_provider.dart'; // UserDataProvider が不要になったので、この行は削除済みのはず
import 'package:provider/provider.dart'; // MultiProvider を使わないので、このimportも不要になります

void main() {
  runApp(
    // ★修正: MultiProvider が不要になったため削除★
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ごみ分別', // タイトルもシンプルに「ごみ分別」に変更をおすすめします
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}