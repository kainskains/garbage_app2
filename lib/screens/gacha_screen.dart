// lib/screens/gacha_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/state/game_state.dart';
import 'package:garbage_app/services/gacha_service.dart';
import 'package:garbage_app/models/gacha_item.dart';
import 'package:garbage_app/models/monster.dart';
import 'package:garbage_app/utils/app_utils.dart';
import 'package:collection/collection.dart'; // ★この行を追加★

class GachaScreen extends StatefulWidget {
  const GachaScreen({Key? key}) : super(key: key);

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  String _gachaResultText = 'ガチャを引いてみよう！';
  Monster? _lastAwardedMonster;

  void _pullGacha() {
    final gameState = Provider.of<GameState>(context, listen: false);
    final gachaService = GachaService();

    if (gameState.gachaTickets <= 0) {
      setState(() {
        _gachaResultText = 'ガチャチケットが足りません！';
        _lastAwardedMonster = null;
      });
      return;
    }

    gameState.addGachaTickets(-1);

    try {
      final GachaItem result = gachaService.pullGacha();

      setState(() {
        _lastAwardedMonster = null;

        if (result.type == 'monster' && result.monsterId != null) {
          // ★ここを修正★
          final Monster? awardedMonster = gachaService.allMonsters.firstWhereOrNull(
                (m) => m.id == result.monsterId,
          );

          if (awardedMonster != null) {
            final newMonsterInstance = Monster(
              id: awardedMonster.id,
              name: awardedMonster.name,
              attribute: awardedMonster.attribute,
              imageUrl: awardedMonster.imageUrl,
              maxHp: awardedMonster.maxHp,
              attack: awardedMonster.attack,
              defense: awardedMonster.defense,
              speed: awardedMonster.speed,
              level: 1,
              currentExp: 0,
              currentHp: awardedMonster.maxHp,
            );
            gameState.addMonster(newMonsterInstance);
            _gachaResultText = '${AppUtils.getAttributeJapaneseName(newMonsterInstance.attribute)}の${newMonsterInstance.name}をゲットしました！';
            _lastAwardedMonster = newMonsterInstance;
            print('新しいモンスターをゲット！ID: ${newMonsterInstance.id}, 名前: ${newMonsterInstance.name}');
          } else {
            _gachaResultText = 'エラー: 未知のモンスターが出現しました。';
          }
        } else if (result.type == 'ticket' && result.ticketAmount != null) {
          gameState.addGachaTickets(result.ticketAmount!);
          _gachaResultText = '${result.ticketAmount}枚のガチャチケットをゲットしました！';
          print('ガチャでチケットをゲット！名前: ${result.name}, 枚数: ${result.ticketAmount}');
        } else if (result.type == 'item') {
          _gachaResultText = '${result.name}をゲットしました！';
          print('ガチャでアイテムをゲット！名前: ${result.name}');
        } else {
          _gachaResultText = '${result.name}をゲットしました！ (タイプ: ${result.type})';
          print('ガチャで不明なアイテムをゲット！名前: ${result.name}, タイプ: ${result.type}');
        }
      });
    } catch (e) {
      setState(() {
        _gachaResultText = 'ガチャを引く際にエラーが発生しました: $e';
        _lastAwardedMonster = null;
      });
      print('ガチャ実行エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ガチャ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '現在のチケット: ${gameState.gachaTickets}枚',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: gameState.gachaTickets > 0 ? _pullGacha : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text('ガチャを引く (1回)'),
            ),
            const SizedBox(height: 30),
            Text(
              _gachaResultText,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            if (_lastAwardedMonster != null) ...[
              const SizedBox(height: 20),
              Image.asset(
                _lastAwardedMonster!.imageUrl,
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              Text(
                '${AppUtils.getAttributeJapaneseName(_lastAwardedMonster!.attribute)} ${_lastAwardedMonster!.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}