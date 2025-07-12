// lib/screens/monster_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/state/game_state.dart';
import 'package:garbage_app/models/monster.dart';

class MonsterListScreen extends StatelessWidget {
  const MonsterListScreen({super.key});

  // 属性を日本語に変換するヘルパーメソッド
  String _getAttributeJapaneseName(MonsterAttribute attribute) {
    switch (attribute) {
      case MonsterAttribute.fire:
        return '火属性';
      case MonsterAttribute.water:
        return '水属性';
      case MonsterAttribute.wood:
        return '木属性';
      case MonsterAttribute.light:
        return '光属性';
      case MonsterAttribute.dark:
        return '闇属性';
      case MonsterAttribute.none:
        return 'ノーマル属性';
      default:
        return '不明';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      // AppBarは_MainScreenで管理されるため、通常は不要。
      // もしこの画面が単独でNavigator.pushされる可能性があるなら、以下を有効化。
      appBar: AppBar(
        title: const Text('モンスター図鑑'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: gameState.monsters.isEmpty
          ? const Center(
        child: Text(
          'まだモンスターがいません。\nごみ分別AIやガチャでモンスターをゲットしよう！',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: gameState.monsters.length,
        itemBuilder: (context, index) {
          final monster = gameState.monsters[index];
          final double expRatio = monster.expToNextLevel > 0
              ? monster.currentExp / monster.expToNextLevel
              : 0.0;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // モンスター画像
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      monster.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // モンスター情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monster.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lv.${monster.level} / ${_getAttributeJapaneseName(monster.attribute)}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.favorite, size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Text('HP: ${monster.maxHp}'),
                            const SizedBox(width: 12),
                            const Icon(Icons.gavel, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text('攻撃: ${monster.attack}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.shield, size: 16, color: Colors.brown),
                            const SizedBox(width: 4),
                            Text('防御: ${monster.defense}'),
                            const SizedBox(width: 12),
                            const Icon(Icons.speed, size: 16, color: Colors.purple),
                            const SizedBox(width: 4),
                            Text('素早さ: ${monster.speed}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 経験値バー
                        if (monster.level < 100) // 例: レベル上限を設定
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXP: ${monster.currentExp} / ${monster.expToNextLevel}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: expRatio,
                                backgroundColor: Colors.grey[300],
                                color: Colors.amber,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}