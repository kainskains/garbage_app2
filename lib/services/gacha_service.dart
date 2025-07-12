// lib/services/gacha_service.dart (全体コード - これで完全に置き換えてください)

import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // debugPrint のために必要
import 'package:collection/collection.dart'; // firstWhereOrNull のために必要

import 'package:garbage_app/models/gacha_item.dart';
import 'package:garbage_app/models/monster.dart';
import 'package:garbage_app/models/stage.dart'; // Stageモデルをインポート

class GachaService {
  static final GachaService _instance = GachaService._internal();
  factory GachaService() => _instance;

  List<GachaItem> _gachaPool = [];
  double _totalWeight = 0.0;
  List<Monster> _allMonsters = []; // JSONからロードされるため、ここでは空で初期化
  List<Stage> _allStages = [];     // JSONからロードされるため、ここでは空で初期化

  bool _isLoaded = false; // 全てのデータロードが完了したかどうかのフラグ

  // ゲッターとして公開
  List<Monster> get allMonsters => _allMonsters;
  List<Stage> get allStages => _allStages;

  GachaService._internal() {
    // シングルトンなので、最初にインスタンスが作られるときに全てのデータをロード
    _loadAllData(); // asyncだけどここではawaitしない
  }

  // 全てのデータをロードする非同期メソッド
  Future<void> _loadAllData() async {
    if (_isLoaded) return; // 既にロード済みなら何もしない

    try {
      // Future.wait を使用して全てのロード処理を並行して実行
      await Future.wait([
        _loadGachaPool(),
        _loadMonsters(),
        _loadStages(),
      ]);
      _isLoaded = true;
      debugPrint('GachaService: 全てのデータロードが完了しました。');
    } catch (e) {
      debugPrint('GachaService Error: データのロード中にエラーが発生しました: $e');
      _isLoaded = false;
      rethrow; // エラーを再スローし、呼び出し元で処理できるようにする
    }
  }

  // 全てのデータがロードされていることを保証するためのメソッド
  Future<void> ensureLoaded() async {
    if (!_isLoaded) {
      await _loadAllData();
    }
  }

  // ガチャプールをロードするメソッド
  Future<void> _loadGachaPool() async {
    try {
      final String response = await rootBundle.loadString('assets/data/gacha_pool.json');
      final List<dynamic> data = json.decode(response);
      _gachaPool = data.map((json) => GachaItem.fromJson(json)).toList();

      _totalWeight = _gachaPool.fold(0.0, (sum, item) => sum + item.weight);
      debugPrint('GachaService: ガチャプールをロードしました。アイテム数: ${_gachaPool.length}, 合計重み: $_totalWeight');
      for (var item in _gachaPool) {
        debugPrint('  - ${item.name} (Type: ${item.type}, Weight: ${item.weight})');
      }
    } catch (e) {
      debugPrint('GachaService Error: ガチャプールのロードに失敗しました: $e');
      _gachaPool = [];
      _totalWeight = 0.0;
      rethrow;
    }
  }

  // ★追加: モンスターデータをロードするメソッド★
  Future<void> _loadMonsters() async {
    try {
      final String response = await rootBundle.loadString('assets/data/monsters.json');
      final List<dynamic> data = json.decode(response);
      _allMonsters = data.map((json) => Monster.fromJson(json)).toList();
      debugPrint('GachaService: モンスターデータをロードしました。モンスター数: ${_allMonsters.length}');
    } catch (e) {
      debugPrint('GachaService Error: モンスターデータのロードに失敗しました: $e');
      _allMonsters = [];
      rethrow;
    }
  }

  // ★追加: ステージデータをロードするメソッド★
  Future<void> _loadStages() async {
    try {
      final String response = await rootBundle.loadString('assets/data/stages.json');
      final List<dynamic> data = json.decode(response);
      _allStages = data.map((json) => Stage.fromJson(json)).toList();
      debugPrint('GachaService: ステージデータをロードしました。ステージ数: ${_allStages.length}');
    } catch (e) {
      debugPrint('GachaService Error: ステージデータのロードに失敗しました: $e');
      _allStages = [];
      rethrow;
    }
  }

  // ★追加: 属性に基づいてランダムなモンスターを返すメソッド★
  Monster getRandomMonsterByAttribute(MonsterAttribute attribute) {
    if (_allMonsters.isEmpty) {
      debugPrint('GachaService Warning: モンスターデータがロードされていません。ダミーモンスターを返します。');
      return Monster(
        id: 'dummy_monster',
        name: 'ダミーモンスター',
        attribute: MonsterAttribute.none,
        imageUrl: 'assets/images/monsters/monster_default.png',
        maxHp: 10, attack: 1, defense: 1, speed: 1, currentHp: 10,
        description: 'モンスターデータが見つからないダミー。',
      );
    }

    final List<Monster> filteredMonsters = _allMonsters
        .where((m) => m.attribute == attribute)
        .toList();

    if (filteredMonsters.isEmpty) {
      debugPrint('GachaService Warning: 属性 $attribute のモンスターが見つかりませんでした。ランダムなモンスターを返します。');
      return _allMonsters[Random().nextInt(_allMonsters.length)];
    }
    return filteredMonsters[Random().nextInt(filteredMonsters.length)];
  }

  // ★追加: ステージIDに基づいて敵モンスターを生成するメソッド★
  Monster generateEnemyMonsterForStage(String stageId) {
    if (_allStages.isEmpty || _allMonsters.isEmpty) {
      debugPrint('GachaService Warning: ステージまたはモンスターデータがロードされていません。デフォルトの敵を返します。');
      return Monster(
        id: 'enemy_default',
        name: '謎の敵',
        attribute: MonsterAttribute.none,
        imageUrl: 'assets/images/monsters/monster_default_enemy.png',
        maxHp: 70, attack: 8, defense: 5, speed: 7, currentHp: 70,
        description: 'ステージまたはモンスターデータが見つからない場合の敵。',
      );
    }

    final stage = _allStages.firstWhereOrNull((s) => s.id == stageId);
    final Random random = Random();

    if (stage == null) {
      debugPrint('GachaService Warning: ステージID "$stageId" が見つかりませんでした。デフォルトの敵を返します。');
      return Monster(
        id: 'enemy_default',
        name: '謎の敵',
        attribute: MonsterAttribute.none,
        imageUrl: 'assets/images/monsters/monster_default_enemy.png',
        maxHp: 70, attack: 8, defense: 5, speed: 7, currentHp: 70,
        description: 'ステージデータが見つからない場合の敵。',
      );
    }

    if (stage.enemyMonsterIds.isEmpty) {
      debugPrint('GachaService Warning: ステージ "$stageId" に敵モンスターが定義されていません。デフォルトの敵を返します。');
      return Monster(
        id: 'enemy_default_no_enemy_in_stage',
        name: '謎の敵（ステージ設定なし）',
        attribute: MonsterAttribute.none,
        imageUrl: 'assets/images/monsters/monster_default_enemy.png',
        maxHp: 70, attack: 8, defense: 5, speed: 7, currentHp: 70,
        description: 'ステージに敵が設定されていない場合の敵。',
      );
    }

    final String selectedEnemyId = stage.enemyMonsterIds[random.nextInt(stage.enemyMonsterIds.length)];

    final enemyTemplate = _allMonsters.firstWhereOrNull((m) => m.id == selectedEnemyId);

    if (enemyTemplate == null) {
      debugPrint('GachaService Warning: 敵モンスターID "$selectedEnemyId" が見つかりませんでした。デフォルトの敵を返します。');
      return Monster(
        id: 'enemy_default_template_missing',
        name: '謎の敵（テンプレートなし）',
        attribute: MonsterAttribute.none,
        imageUrl: 'assets/images/monsters/monster_default_enemy.png',
        maxHp: 70, attack: 8, defense: 5, speed: 7, currentHp: 70,
        description: '敵のデータが見つからない場合の敵。',
      );
    }

    final int enemyLevel = random.nextInt(stage.maxEnemyLevel - stage.minEnemyLevel + 1) + stage.minEnemyLevel;

    return Monster(
      id: 'battle_enemy_${stage.id}_${DateTime.now().millisecondsSinceEpoch}',
      name: enemyTemplate.name,
      attribute: enemyTemplate.attribute,
      imageUrl: enemyTemplate.imageUrl,
      maxHp: enemyTemplate.maxHp,
      attack: enemyTemplate.attack,
      defense: enemyTemplate.defense,
      speed: enemyTemplate.speed,
      level: enemyLevel,
      currentExp: 0,
      currentHp: enemyTemplate.maxHp,
      description: enemyTemplate.description,
    );
  }

  GachaItem pullGacha() {
    if (!_isLoaded || _gachaPool.isEmpty || _totalWeight <= 0) {
      throw Exception('Gacha pool is not loaded or is empty. Ensure GachaService.ensureLoaded() is awaited.');
    }

    final Random random = Random();
    double randomNumber = random.nextDouble() * _totalWeight;
    debugPrint('GachaService: 抽選開始 - 乱数: $randomNumber (合計重み: $_totalWeight)');

    double currentWeight = 0.0;
    for (var item in _gachaPool) {
      currentWeight += item.weight;
      debugPrint('GachaService: アイテム "${item.name}" (重み: ${item.weight}, 現在の累積重み: $currentWeight)');
      if (randomNumber < currentWeight) {
        debugPrint('GachaService: 抽選結果 - ${item.name} (${item.type})');
        return item;
      }
    }

    debugPrint('GachaService: 抽選ロジックで予期せぬ結果。最初のアイテムを返します。');
    return _gachaPool.first;
  }
}