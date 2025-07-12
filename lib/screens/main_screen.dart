// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:garbage_app/screens/gacha_screen.dart';
import 'package:garbage_app/screens/stage_selection_screen.dart'; // ステージ選択画面をインポート (もし別途存在すれば)
import 'package:garbage_app/screens/trash_recognition_screen.dart'; // ★追加: メインの分別機能画面 ★
import 'package:garbage_app/screens/monster_list_screen.dart'; // ★追加: モンスター一覧画面 ★
import 'package:garbage_app/screens/battle_screen.dart'; // ★追加: バトル画面 (直接表示するなら) ★

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 現在選択されているタブのインデックス

  // ★修正: 実際の画面ウィジェットをリストに設定 ★
  late final List<Widget> _widgetOptions; // initStateで初期化するためlate finalにする

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // アプリのメイン機能として「ごみ分別」画面を最初のタブにするのが自然でしょう
      const TrashRecognitionScreen(), // インデックス0: メインの分別機能
      const MonsterListScreen(),      // インデックス1: モンスター一覧
      const StageSelectionScreen(),   // インデックス2: ステージ選択
      const GachaScreen(),            // インデックス3: ガチャ
      // 必要であれば、バトル画面はステージ選択から遷移するので直接ここに含めないことが多い
      // const BattleScreen(stageId: 'default_stage_id'), // もし直接表示するなら
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
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}