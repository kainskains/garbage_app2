// lib/screens/inventory_screen.dart (新規作成)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/state/game_state.dart';
import 'package:garbage_app/models/gacha_item.dart';
import 'package:garbage_app/models/monster.dart'; // Monster をインポート

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // GameState の変更を監視
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // 経験値玉のみをフィルタリング
        final expOrbs = gameState.inventory.where((item) => item.type == GachaItemType.expOrb).toList();
        // 他のアイテムも表示する場合はここにフィルタリングやカテゴリ分けのロジックを追加

        return Scaffold(
          appBar: AppBar(
            title: const Text('インベントリ'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '所持ゴールド: ${gameState.gold}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: expOrbs.isEmpty
                    ? const Center(child: Text('経験値玉がありません。'))
                    : ListView.builder(
                  itemCount: expOrbs.length,
                  itemBuilder: (context, index) {
                    final orb = expOrbs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      elevation: 4.0,
                      child: ListTile(
                        leading: orb.imageUrl != null
                            ? Image.asset(orb.imageUrl!, width: 60, height: 60, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 60, color: Colors.red);
                          },
                        )
                            : const Icon(Icons.auto_awesome, size: 60, color: Colors.amber),
                        title: Text(
                          orb.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '獲得経験値: ${orb.expValue ?? 'N/A'}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showMonsterSelectionDialog(context, orb, gameState);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMonsterSelectionDialog(BuildContext context, GachaItem orb, GameState gameState) {
    if (gameState.monsters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('経験値を与えるモンスターがいません。')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('${orb.name} を使うモンスターを選択'),
          content: SizedBox(
            width: double.maxFinite,
            // モンスターリストが長い場合のためにListViewをラップ
            child: ListView.builder(
              shrinkWrap: true, // コンテンツのサイズに合わせて縮小
              itemCount: gameState.monsters.length,
              itemBuilder: (BuildContext context, int index) {
                final monster = gameState.monsters[index];
                return ListTile(
                  leading: Image.asset(monster.imageUrl, width: 40, height: 40, fit: BoxFit.contain),
                  title: Text('${monster.name} (Lv.${monster.level})'),
                  subtitle: Text('EXP: ${monster.currentExp}/${monster.expToNextLevel}'),
                  onTap: () {
                    gameState.useExperienceOrb(monster.id, orb.id);
                    Navigator.of(dialogContext).pop(); // ダイアログを閉じる
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${monster.name} に ${orb.expValue} 経験値を与えました！')),
                    );
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}