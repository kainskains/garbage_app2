// lib/screens/battle_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/services/gacha_service.dart';
import 'package:garbage_app/models/monster.dart';
import 'package:garbage_app/state/game_state.dart';
import 'package:garbage_app/models/stage.dart';
import 'dart:math';

class BattleScreen extends StatefulWidget {
  final String stageId;
  final Monster playerMonster;

  const BattleScreen({
    super.key,
    required this.stageId,
    required this.playerMonster,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final GachaService _gachaService = GachaService();
  Monster? _enemyMonster;
  Stage? _currentStage;
  bool _isLoadingEnemy = true;
  String? _enemyErrorMessage;

  final List<String> _battleLog = [];
  bool _isBattleInProgress = false;
  bool _isBattleFinished = false;
  String _battleResult = '';

  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // ★ここを削除またはコメントアウト★
    // widget.playerMonster.currentHp = widget.playerMonster.maxHp;
    _generateEnemyAndStage();
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _generateEnemyAndStage() async {
    setState(() {
      _isLoadingEnemy = true;
      _enemyErrorMessage = null;
    });
    try {
      final enemy = _gachaService.generateEnemyMonsterForStage(widget.stageId);
      _currentStage = _gachaService.getAllStages().firstWhere(
            (s) => s.id == widget.stageId,
        orElse: () => throw Exception('Stage with ID ${widget.stageId} not found.'),
      );

      _enemyMonster = Monster(
        id: enemy.id,
        name: enemy.name,
        attribute: enemy.attribute,
        imageUrl: enemy.imageUrl,
        maxHp: enemy.maxHp, // Monsterクラスの変更に応じてbaseMaxHpなどに修正が必要になる可能性あり
        attack: enemy.attack, // baseAttack
        defense: enemy.defense, // baseDefense
        speed: enemy.speed, // baseSpeed
        level: enemy.level,
        currentExp: enemy.currentExp,
        currentHp: enemy.maxHp, // 敵の初期HPは最大HP
      );
      print('敵モンスターを生成しました！: ${_enemyMonster!.name} (Lv.${_enemyMonster!.level})');
      print('ステージ情報をロードしました: ${_currentStage!.name}');
    } catch (e) {
      print('敵モンスターまたはステージ情報の生成に失敗しました: $e');
      setState(() {
        _enemyErrorMessage = '敵モンスターまたはステージ情報の生成に失敗しました: $e';
      });
    } finally {
      setState(() {
        _isLoadingEnemy = false;
      });
    }
  }

  void _startBattle() {
    if (_enemyMonster == null || _isBattleInProgress || _currentStage == null) {
      return;
    }

    setState(() {
      _battleLog.clear();
      _isBattleInProgress = true;
      _isBattleFinished = false;
      _battleResult = '';
    });

    _appendBattleLog('バトル開始！');
    Future.delayed(const Duration(milliseconds: 1000), () => _processBattleTurn());
  }

  void _processBattleTurn() async {
    if (!mounted || _enemyMonster == null) return;

    if (widget.playerMonster.currentHp <= 0) {
      _endBattle('敗北');
      return;
    }
    if (_enemyMonster!.currentHp <= 0) {
      _endBattle('勝利');
      return;
    }

    int playerDamage = max(1, widget.playerMonster.attack - (_enemyMonster!.defense ~/ 2));
    _enemyMonster!.takeDamage(playerDamage);
    _appendBattleLog('${widget.playerMonster.name} の攻撃！ ${_enemyMonster!.name} に $playerDamage ダメージ！');

    if (_enemyMonster!.currentHp <= 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      _endBattle('勝利');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    int enemyDamage = max(1, _enemyMonster!.attack - (widget.playerMonster.defense ~/ 2));
    widget.playerMonster.takeDamage(enemyDamage);
    _appendBattleLog('${_enemyMonster!.name} の攻撃！ ${widget.playerMonster.name} に $enemyDamage ダメージ！');

    if (widget.playerMonster.currentHp <= 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      _endBattle('敗北');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    _processBattleTurn();
  }

  void _appendBattleLog(String message) {
    setState(() {
      _battleLog.add(message);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
      }
    });
  }

  // バトル終了処理
  void _endBattle(String result) {
    setState(() {
      _isBattleInProgress = false;
      _isBattleFinished = true;
      _battleResult = (result == '勝利') ? '敵モンスターを倒した！ 勝利！' : 'あなたのモンスターは倒れてしまった... 敗北！';
      _appendBattleLog('--- バトル終了 ---');
      _appendBattleLog(_battleResult);
    });

    if (result == '勝利' && _currentStage != null) { // プレイヤーHPが0以下で勝利はないので条件から外した
      final gameState = Provider.of<GameState>(context, listen: false);
      final int awardedExp = _currentStage!.baseExpAwarded;
      gameState.gainExpToMonster(widget.playerMonster.id, awardedExp);
      _appendBattleLog('${widget.playerMonster.name} は $awardedExp の経験値を獲得しました！');
    }

    // ★ここに追加: プレイヤーモンスターのHPを最大値に戻す★
    widget.playerMonster.currentHp = widget.playerMonster.maxHp;



    print('Battle finished: $_battleResult');
  }

  Widget _buildHpBar(Monster monster) {
    return ChangeNotifierProvider.value(
      value: monster,
      child: Consumer<Monster>(
        builder: (context, currentMonster, child) {
          double hpRatio = currentMonster.currentHp / currentMonster.maxHp;
          Color barColor = Colors.green;
          if (hpRatio < 0.2) {
            barColor = Colors.red;
          } else if (hpRatio < 0.5) {
            barColor = Colors.orange;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${currentMonster.name} HP: ${currentMonster.currentHp}/${currentMonster.maxHp} (Lv.${currentMonster.level})',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: hpRatio,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 15,
                borderRadius: BorderRadius.circular(8),
              ),
              if (monster == widget.playerMonster)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    'EXP: ${currentMonster.currentExp}/${currentMonster.expToNextLevel}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('バトル画面'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'ステージID: ${widget.stageId}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _isLoadingEnemy
                    ? const CircularProgressIndicator()
                    : _enemyErrorMessage != null
                    ? Text(
                  _enemyErrorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                )
                    : _enemyMonster != null
                    ? Column(
                  children: [
                    Text(
                      '敵: ${_enemyMonster!.name} (Lv.${_enemyMonster!.level})',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                    const SizedBox(height: 10),
                    Image.asset(
                      _enemyMonster!.imageUrl,
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, size: 100, color: Colors.red);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildHpBar(_enemyMonster!),
                  ],
                )
                    : const Text(
                  '敵モンスターを生成できませんでした。',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                _buildHpBar(widget.playerMonster),
                const SizedBox(height: 30),

                if (_isBattleInProgress)
                  const Text(
                    'バトル中...',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  )
                else if (_isBattleFinished)
                  Column(
                    children: [
                      Text(
                        _battleResult,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _battleResult.contains('勝利') ? Colors.green : Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          textStyle: const TextStyle(fontSize: 20),
                        ),
                        child: const Text('戻る'),
                      ),
                    ],
                  )
                else if (_enemyMonster != null && _currentStage != null)
                    ElevatedButton(
                      onPressed: _startBattle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 20),
                      ),
                      child: const Text('バトル開始！'),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white.withOpacity(0.9),
              ),
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: _battleLog.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      _battleLog[index],
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}