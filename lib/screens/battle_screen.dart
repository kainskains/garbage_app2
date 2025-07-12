// lib/screens/battle_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider を使用
import 'package:garbage_app/services/gacha_service.dart';
import 'package:garbage_app/models/monster.dart';
import 'dart:math'; // ダメージ計算に必要

class BattleScreen extends StatefulWidget {
  final String stageId;
  final Monster playerMonster; // プレイヤーが選んだモンスター

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
  Monster? _enemyMonster; // 敵モンスター
  bool _isLoadingEnemy = true;
  String? _enemyErrorMessage;

  // バトル状態管理
  final List<String> _battleLog = []; // バトルログ
  bool _isBattleInProgress = false; // バトル進行中か
  bool _isBattleFinished = false; // バトル終了か
  String _battleResult = ''; // バトルの結果

  // バトルログのスクロール制御用
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // プレイヤーモンスターの現在のHPを最大HPに戻す (バトル開始時に常に全回復)
    // これは簡易的な対応。永続的なHP管理はGameStateで行うべき
    widget.playerMonster.currentHp = widget.playerMonster.maxHp;
    _generateEnemy();
  }

  @override
  void dispose() {
    _logScrollController.dispose(); // Controllerの破棄
    super.dispose();
  }

  // 敵モンスター生成ロジック
  Future<void> _generateEnemy() async {
    setState(() {
      _isLoadingEnemy = true;
      _enemyErrorMessage = null;
    });
    try {
      // 敵モンスターはGameStateの管理外なので、新しく生成されるたびにChangeNotifierProviderでラップする
      final enemy = _gachaService.generateEnemyMonsterForStage(widget.stageId);
      _enemyMonster = Monster( // GachaServiceから受け取ったデータで新しいMonsterインスタンスを作成
        id: enemy.id,
        name: enemy.name,
        attribute: enemy.attribute,
        imageUrl: enemy.imageUrl,
        maxHp: enemy.maxHp,
        attack: enemy.attack,
        defense: enemy.defense,
        speed: enemy.speed,
        level: enemy.level,
      );
      print('敵モンスターを生成しました！: ${_enemyMonster!.name} (Lv.${_enemyMonster!.level})');
    } catch (e) {
      print('敵モンスターの生成に失敗しました: $e');
      setState(() {
        _enemyErrorMessage = '敵モンスターの生成に失敗しました: $e';
      });
    } finally {
      setState(() {
        _isLoadingEnemy = false;
      });
    }
  }

  // バトル開始処理
  void _startBattle() {
    if (_enemyMonster == null || _isBattleInProgress) {
      return;
    }

    // バトルログと状態をリセット
    setState(() {
      _battleLog.clear();
      _isBattleInProgress = true;
      _isBattleFinished = false;
      _battleResult = '';
    });

    _appendBattleLog('バトル開始！');
    // バトルは非同期でターンを進める
    Future.delayed(const Duration(milliseconds: 1000), () => _processBattleTurn());
  }

  // バトルターン処理 (非同期)
  void _processBattleTurn() async {
    if (!mounted || _enemyMonster == null) return;

    // バトル終了条件チェック
    if (widget.playerMonster.currentHp <= 0) {
      _endBattle('敗北');
      return;
    }
    if (_enemyMonster!.currentHp <= 0) {
      _endBattle('勝利');
      return;
    }

    // 1. プレイヤーの攻撃
    // ダメージ計算 (仮: 属性相性は未実装)
    int playerDamage = max(1, widget.playerMonster.attack - (_enemyMonster!.defense ~/ 2));
    _enemyMonster!.takeDamage(playerDamage);
    _appendBattleLog('${widget.playerMonster.name} の攻撃！ ${_enemyMonster!.name} に $playerDamage ダメージ！');

    // 敵のHPが0になったら終了
    if (_enemyMonster!.currentHp <= 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      _endBattle('勝利');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000)); // 攻撃間のウェイト

    // 2. 敵の攻撃
    int enemyDamage = max(1, _enemyMonster!.attack - (widget.playerMonster.defense ~/ 2));
    widget.playerMonster.takeDamage(enemyDamage);
    _appendBattleLog('${_enemyMonster!.name} の攻撃！ ${widget.playerMonster.name} に $enemyDamage ダメージ！');

    // プレイヤーのHPが0になったら終了
    if (widget.playerMonster.currentHp <= 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      _endBattle('敗北');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000)); // ターン間のウェイト

    // 次のターンへ
    _processBattleTurn();
  }

  // バトルログを追加し、スクロール位置を調整
  void _appendBattleLog(String message) {
    setState(() {
      _battleLog.add(message);
    });
    // 次のフレームでスクロールする
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
    print('Battle finished: $_battleResult');
  }

  // HPバーウィジェット (ChangeNotifierProviderとConsumerでHPの変化をリッスン)
  Widget _buildHpBar(Monster monster) {
    return ChangeNotifierProvider.value( // MonsterインスタンスをProviderで提供
      value: monster,
      child: Consumer<Monster>( // Monsterの変更をリッスン
        builder: (context, currentMonster, child) {
          double hpRatio = currentMonster.currentHp / currentMonster.maxHp;
          Color barColor = Colors.green;
          if (hpRatio < 0.2) {
            barColor = Colors.red;
          } else if (hpRatio < 0.5) {
            barColor = Colors.orange;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 幅いっぱいに広げる
            children: [
              Text(
                '${currentMonster.name} HP: ${currentMonster.currentHp}/${currentMonster.maxHp}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: hpRatio,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 15, // バーの高さ
                borderRadius: BorderRadius.circular(8), // 角丸
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
      // body の直下を Column にし、レイアウトを厳密に制御
      body: Column(
        children: [
          // 上部固定エリア（プレイヤー、敵モンスター情報、ボタン）
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'ステージID: ${widget.stageId}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // 敵モンスター情報
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
                    // アセットロードエラー対策
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

                // プレイヤーモンスター情報
                Text(
                  'あなたのモンスター: ${widget.playerMonster.name} (Lv.${widget.playerMonster.level})',
                  style: const TextStyle(fontSize: 20, color: Colors.blue),
                ),
                _buildHpBar(widget.playerMonster),
                const SizedBox(height: 30),

                // バトル開始/終了ボタンと結果表示
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
                          // バトル終了後、前の画面に戻る (ステージ選択画面)
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
                else if (_enemyMonster != null) // 敵がいる場合のみバトル開始ボタンを表示
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
          const SizedBox(height: 20), // バトルログとの間隔

          // バトルログ表示エリア（Expanded で残りスペースを埋める）
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
                controller: _logScrollController, // スクロール制御を適用
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
          const SizedBox(height: 16), // 画面下部のパディング
        ],
      ),
    );
  }
}