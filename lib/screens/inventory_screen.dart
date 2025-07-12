import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/state/game_state.dart';
import 'package:garbage_app/models/gacha_item.dart';
import 'package:garbage_app/models/monster.dart'; // Monster をインポート

// InventoryScreen を StatefulWidget に変更します
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // アイテムをグループ化して数量を管理するマップ
  Map<String, List<GachaItem>> _groupedExpOrbs = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _groupItems(Provider.of<GameState>(context, listen: false).inventory);
  }

  // インベントリのアイテムをグループ化するメソッド
  void _groupItems(List<GachaItem> inventory) {
    _groupedExpOrbs = {};
    for (var item in inventory) {
      if (item.type == GachaItemType.expOrb) {
        // 同じIDの経験値玉をグループ化
        _groupedExpOrbs.putIfAbsent(item.id, () => []).add(item);
      }
      // 他のアイテムタイプもグループ化する場合はここに追加
    }
    // 状態を更新してUIに反映
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // GameStateのinventoryが更新されたらアイテムを再グループ化
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _groupItems(gameState.inventory);
        });

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
                child: _groupedExpOrbs.isEmpty
                    ? const Center(child: Text('経験値玉がありません。'))
                    : ListView.builder(
                  itemCount: _groupedExpOrbs.length,
                  itemBuilder: (context, index) {
                    final orbId = _groupedExpOrbs.keys.elementAt(index);
                    final orbList = _groupedExpOrbs[orbId]!;
                    final orb = orbList.first; // グループの代表アイテム
                    final count = orbList.length; // そのアイテムの合計数量

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
                          '${orb.name} x $count', // 数量を表示
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '獲得経験値: ${orb.expValue ?? 'N/A'}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // 数量選択ダイアログを表示
                          _showQuantitySelectionDialog(context, orb, count, gameState);
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

  // 数量選択ダイアログを表示するメソッド
  void _showQuantitySelectionDialog(BuildContext context, GachaItem orb, int maxQuantity, GameState gameState) {
    int selectedQuantity = 1; // デフォルトは1個

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // ダイアログ内の状態を更新するためにStatefulBuilderを使用
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text('${orb.name} を使う数量を選択'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('使用する数量: $selectedQuantity / $maxQuantity'),
                  Slider(
                    value: selectedQuantity.toDouble(),
                    min: 1,
                    max: maxQuantity.toDouble(),
                    divisions: maxQuantity > 1 ? maxQuantity - 1 : 1, // 1個の場合はdivisionsを0にしない
                    label: selectedQuantity.round().toString(),
                    onChanged: (double value) {
                      setStateInDialog(() {
                        selectedQuantity = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  // モンスター選択部分
                  SizedBox(
                    width: double.maxFinite,
                    height: MediaQuery.of(context).size.height * 0.3, // 高さ制限を追加
                    child: gameState.monsters.isEmpty
                        ? const Center(child: Text('経験値を与えるモンスターがいません。'))
                        : ListView.builder(
                      shrinkWrap: true,
                      itemCount: gameState.monsters.length,
                      itemBuilder: (BuildContext context, int index) {
                        final monster = gameState.monsters[index];
                        return ListTile(
                          leading: Image.asset(monster.imageUrl, width: 40, height: 40, fit: BoxFit.contain),
                          title: Text('${monster.name} (Lv.${monster.level})'),
                          subtitle: Text('EXP: ${monster.currentExp}/${monster.expToNextLevel}'),
                          onTap: () {
                            // 選択された数量とモンスターIDを渡して使用
                            gameState.useExperienceOrbBatch(monster.id, orb.id, selectedQuantity);
                            Navigator.of(dialogContext).pop(); // ダイアログを閉じる
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${monster.name} に ${orb.expValue! * selectedQuantity} 経験値を与えました！')),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
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
      },
    );
  }
}