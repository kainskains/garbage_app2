// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:garbage_app/screens/gacha_screen.dart';
import 'package:garbage_app/screens/stage_selection_screen.dart';
import 'package:garbage_app/screens/trash_recognition_screen.dart';
import 'package:garbage_app/screens/monster_list_screen.dart';
import 'package:garbage_app/screens/inventory_screen.dart'; // ★追加: インベントリ画面をインポート★

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
      const MonsterListScreen(),      // インデックス1: モンスター一覧
      const StageSelectionScreen(),   // インデックス2: ステージ選択
      const GachaScreen(),            // インデックス3: ガチャ
      const InventoryScreen(),        // ★追加: インデックス4: インベントリ★
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
        title: const Text('ごみ分別モンスターズ'),
        backgroundColor: Colors.green,
        // AppBarにアクションボタンは不要になる (BottomNavigationBarで対応するため)
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
          BottomNavigationBarItem(
            icon: Icon(Icons.pets), // モンスターっぽいアイコン
            label: 'モンスター',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map), // ステージっぽいアイコン
            label: 'ステージ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino), // ガチャっぽいアイコン
            label: 'ガチャ',
          ),
          BottomNavigationBarItem( // ★追加: インベントリタブ★
            icon: Icon(Icons.inventory), // インベントリっぽいアイコン
            label: 'インベントリ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // アイテム数が多い場合はfixedが推奨
      ),
    );
  }
}
