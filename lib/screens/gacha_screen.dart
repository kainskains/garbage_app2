import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/state/game_state.dart';
import 'package:garbage_app/services/gacha_service.dart';
import 'package:garbage_app/models/gacha_item.dart';
import 'package:garbage_app/models/monster.dart';
import 'package:garbage_app/utils/app_utils.dart'; // AppUtils が必要に応じて含まれているか確認
import 'package:collection/collection.dart'; // firstWhereOrNull のために必要
import 'package:garbage_app/widgets/gacha_result_dialog.dart'; // ガチャ結果ダイアログをインポート

class GachaScreen extends StatefulWidget {
  const GachaScreen({Key? key}) : super(key: key);

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  // GachaServiceのシングルトンインスタンスを取得
  final GachaService _gachaService = GachaService();

  @override
  void initState() {
    super.initState();
    // 画面が初期化されたときにガチャプールがロードされていることを保証
    // GachaServiceがシングルトンかつ、一度しかロードしないロジックなので、
    // ここで ensureLoaded を呼んでおけば、_pullGacha で再度 await するのは冗長ではない。
    _gachaService.ensureLoaded();
  }

  void _pullGacha() async {
    // ガチャプールが確実にロードされるまで待機
    await _gachaService.ensureLoaded();

    final gameState = Provider.of<GameState>(context, listen: false);

    if (gameState.gachaTickets <= 0) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('ガチャチケットが足りません'),
            content: const Text('ガチャを引くにはチケットが必要です。'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    gameState.addGachaTickets(-1); // ガチャチケットを1枚消費

    try {
      final GachaItem result = _gachaService.pullGacha(); // GachaServiceのインスタンスを利用

      // モンスターはガチャから出ない設定なので、このブロックは基本的に実行されない
      if (result.type == 'monster' && result.monsterId != null) {
        final Monster? awardedMonsterTemplate = _gachaService.allMonsters.firstWhereOrNull(
              (m) => m.id == result.monsterId,
        );

        if (awardedMonsterTemplate != null) {
          final newMonsterInstance = Monster(
            id: 'gacha_${DateTime.now().microsecondsSinceEpoch}', // ユニークなIDを生成
            name: awardedMonsterTemplate.name,
            attribute: awardedMonsterTemplate.attribute,
            imageUrl: awardedMonsterTemplate.imageUrl, // allMonstersのimageUrlパスが正しいことを前提
            maxHp: awardedMonsterTemplate.maxHp,
            attack: awardedMonsterTemplate.attack,
            defense: awardedMonsterTemplate.defense,
            speed: awardedMonsterTemplate.speed,
            level: 1, // ガチャで獲得したモンスターはレベル1から
            currentExp: 0,
            currentHp: awardedMonsterTemplate.maxHp, // HPは最大値で初期化
            description: awardedMonsterTemplate.description,
          );
          gameState.addMonster(newMonsterInstance); // ゲーム状態にモンスターを追加

          // ガチャ結果ダイアログを表示
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return GachaResultDialog(obtainedMonster: newMonsterInstance);
            },
          );
        } else {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('エラー'),
                content: const Text('未知のモンスターが出現しました。開発者にお問い合わせください。'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } else if (result.type == 'ticket' && result.ticketAmount != null) {
        // チケット獲得の場合
        gameState.addGachaTickets(result.ticketAmount!);
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('ガチャ結果！'),
              content: Text('${result.ticketAmount}枚のガチャチケットをゲットしました！'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else if (result.type == 'item') {
        // アイテム獲得の場合
        // TODO: 実際のアイテム獲得ロジックをここに追加する（例: アイテムインベントリに追加など）
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('ガチャ結果！'),
              content: Text('${result.name}をゲットしました！'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        // その他の不明な結果の場合
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('ガチャ結果！'),
              content: Text('${result.name}をゲットしました！ (タイプ: ${result.type})'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('エラーが発生しました'),
            content: Text('ガチャを引く際にエラーが発生しました: $e'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      debugPrint('ガチャ実行エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ガチャ'),
        centerTitle: true,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Text(
                '現在のチケット: ${gameState.gachaTickets}枚',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: gameState.gachaTickets > 0 ? _pullGacha : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.stars, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'ガチャを引く (1回)',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'ガチャを引いてみよう！\n新しいアイテムをゲットできるかも！？', // メッセージをアイテム向けに調整
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}