// lib/screens/monster_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/monster.dart';
import 'package:garbage_app/state/game_state.dart';
import 'package:garbage_app/screens/battle_screen.dart'; // バトル画面への遷移に必要

class MonsterSelectionScreen extends StatelessWidget {
  // ★ここを以前の状態に戻す（selectedStageId を追加）★
  final String selectedStageId; // ★この行を追加★

  const MonsterSelectionScreen({
    super.key,
    required this.selectedStageId, // ★この行を追加★
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('モンスター図鑑'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          if (gameState.monsters.isEmpty) {
            return const Center(
              child: Text(
                'まだモンスターがいません。\nガチャを引いて仲間を増やしましょう！',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: gameState.monsters.length,
            itemBuilder: (context, index) {
              final monster = gameState.monsters[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: monster.imageUrl.isNotEmpty
                      ? Image.asset(
                    monster.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 50, color: Colors.red);
                    },
                  )
                      : const Icon(Icons.help_outline, size: 50),
                  title: Text(
                    monster.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Lv.${monster.level} / HP:${monster.maxHp} / 属性: ${monster.attribute.displayName}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      gameState.setSelectedPlayerMonster(monster);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BattleScreen(
                            // ★ここを修正: selectedStageId を BattleScreen に渡す★
                            stageId: selectedStageId, // ここを 'stage_001' から変更
                            playerMonster: monster, // 選択したモンスターを渡す
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('選ぶ'),
                  ),
                  onTap: () {
                    print('${monster.name} が選択されました。');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}