import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/state/game_state.dart';
import 'package:garbage_app/models/monster.dart';
import 'package:garbage_app/screens/monster_detail_screen.dart';

// 並び替えオプションのEnumを定義
enum MonsterSortOption {
  attribute, // 属性順
  acquisitionOrder, // 入手順
  levelAsc, // レベル昇順
  levelDesc, // レベル降順
}

class MonsterListScreen extends StatefulWidget {
  const MonsterListScreen({super.key});

  @override
  State<MonsterListScreen> createState() => _MonsterListScreenState();
}

class _MonsterListScreenState extends State<MonsterListScreen> {
  // 現在選択されている並び替えオプション
  MonsterSortOption _selectedSortOption = MonsterSortOption.attribute;

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
    }
  }

  // 並び替えオプションの表示名を取得するヘルパーメソッド
  String _getSortOptionDisplayName(MonsterSortOption option) {
    switch (option) {
      case MonsterSortOption.attribute:
        return '属性順';
      case MonsterSortOption.acquisitionOrder:
        return '入手順';
      case MonsterSortOption.levelAsc:
        return 'レベル昇順';
      case MonsterSortOption.levelDesc:
        return 'レベル降順';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    List<Monster> displayMonsters;

    // 選択された並び替えオプションに基づいてモンスターリストを選択
    switch (_selectedSortOption) {
      case MonsterSortOption.attribute:
        displayMonsters = gameState.sortedMonstersByAttribute;
        break;
      case MonsterSortOption.acquisitionOrder:
        displayMonsters = gameState.monsters; // GameStateのデフォルトリストが入手順
        break;
      case MonsterSortOption.levelAsc:
        displayMonsters = gameState.sortedMonstersByLevelAsc;
        break;
      case MonsterSortOption.levelDesc:
        displayMonsters = gameState.sortedMonstersByLevelDesc;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('モンスター図鑑'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // 並び替えオプションのドロップダウン
          DropdownButton<MonsterSortOption>(
            value: _selectedSortOption,
            icon: const Icon(Icons.sort, color: Colors.white),
            underline: Container(), // 下線を非表示にする
            onChanged: (MonsterSortOption? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedSortOption = newValue;
                });
              }
            },
            items: MonsterSortOption.values.map((MonsterSortOption option) {
              return DropdownMenuItem<MonsterSortOption>(
                value: option,
                child: Text(_getSortOptionDisplayName(option), style: const TextStyle(color: Colors.black)),
              );
            }).toList(),
          ),
        ],
      ),
      body: displayMonsters.isEmpty
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
        itemCount: displayMonsters.length,
        itemBuilder: (context, index) {
          final monster = displayMonsters[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MonsterDetailScreen(monster: monster),
                ),
              );
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
