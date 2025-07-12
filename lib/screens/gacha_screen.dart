// lib/screens/gacha_screen.dart (例)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // GameStateを利用するために必要
import 'package:garbage_app/state/game_state.dart'; // GameStateをインポート

class GachaScreen extends StatelessWidget { // または StatefulWidget
  const GachaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // GameStateのデータにアクセスする例
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ガチャ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('現在のチケット: ${gameState.gachaTickets}枚'),
            ElevatedButton(
              onPressed: () {
                // ここでガチャを引くロジックを呼び出す
                // 例: GachaService().pullGacha();
                // 必要に応じてgameState.addMonster()なども呼び出す
              },
              child: const Text('ガチャを引く'),
            ),
            // 他のUI要素
          ],
        ),
      ),
    );
  }
}