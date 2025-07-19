// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:garbage_app/screens/trash_recognition_screen.dart';
import 'package:garbage_app/screens/settings_screen.dart'; // ★追加: 設定画面をインポート★

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 現在選択されているタブのインデックス

  late final List<Widget> _widgetOptions; // initStateで初期化するためlate finalにする

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const TrashRecognitionScreen(), // インデックス0: メインの分別機能
      const SettingsScreen(),         // ★追加: インデックス1: 設定画面★
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ごみ分別'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex), // 選択された画面を表示
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt), // 分別機能っぽいアイコン
            label: '分別',
          ),
          BottomNavigationBarItem( // ★追加: 設定タブ★
            icon: Icon(Icons.settings), // 設定っぽいアイコン
            label: '設定',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // アイテム数に応じてfixedかshiftingを選択
      ),
    );
  }
}