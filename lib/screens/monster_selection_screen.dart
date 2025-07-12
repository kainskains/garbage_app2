// lib/screens/monster_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/monster.dart';
import 'package:garbage_app/state/game_state.dart';
import 'package:garbage_app/screens/battle_screen.dart';

class MonsterSelectionScreen extends StatefulWidget {
  // ★修正: selectedStageId を受け取るためのフィールドを追加 ★
  final String selectedStageId;

  // ★修正: コンストラクタで selectedStageId を必須引数として受け取る ★
  const MonsterSelectionScreen({
    super.key,
    required this.selectedStageId,
  });

  @override
  State<MonsterSelectionScreen> createState() => _MonsterSelectionScreenState();
}

class _MonsterSelectionScreenState extends State<MonsterSelectionScreen> {
  // MonsterSelectionScreen は StageSelectionScreen から selectedStageId を受け取るため、
  // ここでステージデータをロードする GachaService や関連する変数は不要になります。
  // final GachaService _gachaService = GachaService();
  // List<Stage> _availableStages = [];
  // bool _isLoadingStages = true;
  // String? _stageLoadError;

  @override
  void initState() {
    super.initState();
    // ここでのステージロードは不要になります。
    // _loadStages();
  }

  // _loadStages メソッドも不要になります。
  // Future<void> _loadStages() async { ... }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final List<Monster> ownedMonsters = gameState.monsters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('バトルに出すモンスターを選択'), // 役割に合わせてタイトルを変更
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ownedMonsters.isEmpty
          ? const Center(
        child: Text(
          'バトルできるモンスターがいません。\nごみ分別AIでモンスターをゲットしよう！',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'ステージID: ${widget.selectedStageId} に出撃するモンスターを選ぼう！', // 受け取ったステージIDを表示
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple[800]),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: ownedMonsters.length,
              itemBuilder: (context, index) {
                final monster = ownedMonsters[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: Image.asset(monster.imageUrl, width: 50, height: 50, fit: BoxFit.contain),
                    title: Text(
                      monster.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    // MonsterAttributeExtension の displayName を使用
                    subtitle: Text('Lv.${monster.level} / HP:${monster.currentHp}/${monster.maxHp} / 属性: ${monster.attribute.displayName}'),
                    onTap: () {
                      // ダイアログは不要なので削除 (Card の onTap に直接遷移ロジックを記述)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BattleScreen(
                            playerMonster: monster,
                            stageId: widget.selectedStageId, // 受け取ったステージIDを BattleScreen に渡す
                          ),
                        ),
                      );
                      print('Selected player monster: ${monster.name} for stage: ${widget.selectedStageId}');
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}