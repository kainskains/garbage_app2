// lib/screens/monster_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/state/game_state.dart';
import 'package:garbage_app/models/monster.dart';
import 'package:garbage_app/screens/monster_detail_screen.dart'; // ★ここを追加★

class MonsterListScreen extends StatelessWidget {
  const MonsterListScreen({super.key});

  // 属性を日本語に変換するヘルパーメソッド (これはそのまま残します)
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
    // default: return '不明'; // 全てのケースを網羅していれば不要
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
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
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.8,
        ),
        itemCount: gameState.monsters.length,
        itemBuilder: (context, index) {
          final monster = gameState.monsters[index];

          return GestureDetector(
            onTap: () {
              // ★ここを修正: モンスター詳細画面へ遷移するロジックを有効化★
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MonsterDetailScreen(monster: monster), // タップしたモンスターを渡す
                ),
              );
              // print('${monster.name} がタップされました（詳細表示へ遷移）'); // 不要になるため削除
            },
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: monster.imageUrl.isNotEmpty
                          ? Image.asset(
                        monster.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 60, color: Colors.grey);
                        },
                      )
                          : const Icon(Icons.help_outline, size: 60, color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
                    child: Text(
                      'Lv.${monster.level}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // 必要であれば、名前もコンパクトに追加
                  // Padding(
                  //   padding: const EdgeInsets.only(bottom: 4.0),
                  //   child: Text(
                  //     monster.name,
                  //     maxLines: 1,
                  //     overflow: TextOverflow.ellipsis,
                  //     style: const TextStyle(
                  //       fontSize: 12,
                  //       color: Colors.black54,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}