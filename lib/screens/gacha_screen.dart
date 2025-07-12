import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/state/game_state.dart';
import 'package:garbage_app/models/gacha_item.dart';
import 'package:garbage_app/models/monster.dart'; // Monsterはガチャからは出さないが、他の場所で使う可能性があるのでインポートは残す
import 'dart:math' as math; // For random number generation

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  GachaItem? _gachaResult;
  bool _isPulling = false;

  // Define your gacha pool here using the updated GachaItem structure
  // ガチャから出てくるアイテムを経験値玉（小、中、大、特大）の4つだけに限定しました
  final List<GachaItem> _gachaPool = [
    GachaItem(
      id: 'exp_orb_small_gacha_001',
      name: '経験値玉（小）',
      type: GachaItemType.expOrb,
      imageUrl: 'assets/images/items/exp_orb_small.png', // アセットパスに変更
      description: '少量の経験値が手に入る経験値玉です。',
      expValue: 50,
      weight: 400, // 出現確率を調整
    ),
    GachaItem(
      id: 'exp_orb_medium_gacha_001',
      name: '経験値玉（中）',
      type: GachaItemType.expOrb,
      imageUrl: 'assets/images/items/exp_orb_medium.png', // アセットパスに変更
      description: '中程度の経験値が手に入る経験値玉です。',
      expValue: 200,
      weight: 250, // 出現確率を調整
    ),
    GachaItem(
      id: 'exp_orb_large_gacha_001',
      name: '経験値玉（大）',
      type: GachaItemType.expOrb,
      imageUrl: 'assets/images/items/exp_orb_large.png', // アセットパスに変更
      description: '大量の経験値が手に入る経験値玉です。',
      expValue: 800,
      weight: 100, // 出現確率を調整
    ),
    GachaItem(
      id: 'exp_orb_xl_gacha_001',
      name: '経験値玉（特大）',
      type: GachaItemType.expOrb,
      imageUrl: 'assets/images/items/exp_orb_xl.png', // アセットパスに変更
      description: '非常に大量の経験値が手に入る貴重な経験値玉です。',
      expValue: 3000,
      weight: 20, // 出現確率を調整
    ),
  ];

  void _pullGacha() async {
    final gameState = Provider.of<GameState>(context, listen: false);

    if (gameState.gachaTickets <= 0) {
      _showAlertDialog('チケット不足', 'ガチャチケットが足りません！');
      return;
    }

    setState(() {
      _isPulling = true;
      _gachaResult = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    gameState.addGachaTickets(-1); // ガチャチケットを1枚消費

    // ガチャの重みに基づいてアイテムを選択
    final totalWeight = _gachaPool.fold(0.0, (sum, item) => sum + (item.weight ?? 0.0));
    double randomPoint = math.Random().nextDouble() * totalWeight;
    GachaItem result = _gachaPool.first; // デフォルト値
    for (var item in _gachaPool) {
      if (item.weight != null) {
        randomPoint -= item.weight!;
        if (randomPoint < 0) {
          result = item;
          break;
        }
      }
    }

    setState(() {
      _gachaResult = result;
      _isPulling = false;
    });

    _handleGachaResult(result, gameState);
  }

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _handleGachaResult(GachaItem result, GameState gameState) {
    String message;
    switch (result.type) {
      case GachaItemType.expOrb:
        if (result.expValue != null) {
          gameState.addInventoryItem(result); // 経験値玉をインベントリに追加
          message = '${result.expValue}経験値の${result.name}をゲットしました！';
        } else {
          message = '経験値玉をゲットしましたが、経験値量が不明です。';
        }
        break;
      default:
        message = '何かが当たりました！';
        break;
    }

    _showAlertDialog('ガチャ結果', message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ガチャ'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack( // 背景画像のためにStackを追加
        children: [
          // 背景画像
          Positioned.fill(
            child: Image.asset(
              'assets/images/items/treasure_box.png', // 仮の背景画像パス
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.blueGrey[100]); // エラー時の代替色
              },
            ),
          ),
          // その他のコンテンツ
          Consumer<GameState>(
            builder: (context, gameState, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 現在のチケット表示
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7), // 半透明の背景
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '現在のチケット: ${gameState.gachaTickets}枚',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black), // 文字色を黒に
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: gameState.gachaTickets > 0 ? _pullGacha : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          textStyle: const TextStyle(fontSize: 20),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: _isPulling
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('ガチャを引く'),
                      ),
                      const SizedBox(height: 30),
                      if (_gachaResult != null) ...[
                        // 結果表示
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7), // 半透明の背景
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            '結果: ${_gachaResult!.name}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black), // 文字色を黒に
                          ),
                        ),
                        const SizedBox(height: 20),
                        Image.asset(
                          _gachaResult!.imageUrl ?? 'assets/images/placeholder.png', // Fallbackをアセットパスに変更
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 150,
                              height: 150,
                              color: Colors.grey,
                              child: const Icon(Icons.broken_image, color: Colors.white),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7), // 半透明の背景
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _gachaResult!.description ?? '説明なし', // Use null-aware operator
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.black87), // 文字色を黒に
                          ),
                        ),
                      ],
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          textStyle: const TextStyle(fontSize: 18),
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('戻る'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
