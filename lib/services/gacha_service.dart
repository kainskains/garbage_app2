// lib/services/gacha_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:garbage_app/models/gacha_item.dart';
import 'package:garbage_app/models/monster.dart';
import 'package:garbage_app/models/stage.dart';

class GachaService {
  static final GachaService _instance = GachaService._internal();

  factory GachaService() {
    return _instance;
  }

  GachaService._internal();

  List<GachaItem> _gachaPool = [];
  List<Monster> _allMonsters = []; // 全てのモンスターを保持
  List<Stage> _allStages = []; // 全てのステージを保持

  // ★追加または確認：_allMonstersへの公開ゲッター★
  List<Monster> get allMonsters => _allMonsters;

  double _totalWeight = 0.0; // ガチャプールの合計重み

  Future<void> loadGachaPool() async {
    try {
      final String response = await rootBundle.loadString('assets/data/gacha_pool.json');
      print('gacha_pool.json content loaded. Length: ${response.length}');
      final List<dynamic> data = json.decode(response);

      _gachaPool = data.map((json) => GachaItem.fromJson(json)).toList();
      _totalWeight = _gachaPool.fold(0.0, (sum, item) => sum + item.weight);
      print('Gacha pool loaded successfully: ${_gachaPool.length} items, Total weight: $_totalWeight');
    } catch (e, stacktrace) {
      print('Error loading gacha_pool.json: $e');
      print('Stacktrace: $stacktrace');
      _gachaPool = [];
      _totalWeight = 0.0;
    }
  }

  Future<void> loadMonsters() async {
    try {
      final String response = await rootBundle.loadString('assets/data/monsters.json');
      final List<dynamic> data = json.decode(response);
      _allMonsters = data.map((json) => Monster.fromJson(json)).toList();
      print('Monsters loaded successfully: ${_allMonsters.length} items');
    } catch (e, stacktrace) {
      print('Error loading monsters.json: $e');
      print('Stacktrace: $stacktrace');
      _allMonsters = [];
    }
  }

  Future<void> loadStages() async {
    try {
      final String response = await rootBundle.loadString('assets/data/stages.json');
      final List<dynamic> data = json.decode(response);
      _allStages = data.map((json) => Stage.fromJson(json)).toList();
      print('Stages loaded successfully: ${_allStages.length} items');
    } catch (e, stacktrace) {
      print('Error loading stages.json: $e');
      print('Stacktrace: $stacktrace');
      _allStages = [];
    }
  }

  List<Stage> getAllStages() {
    return _allStages;
  }

  Monster generateEnemyMonsterForStage(String stageId) {
    final stage = _allStages.firstWhere(
          (s) => s.id == stageId,
      orElse: () {
        print('Warning: Stage with ID $stageId not found. Using default stage settings.');
        return Stage(
          id: 'default_stage',
          name: 'デフォルトステージ',
          description: 'ステージデータが見つかりませんでした。',
          enemyMonsterIds: _allMonsters.isNotEmpty ? [_allMonsters.first.id] : [],
          baseExpAwarded: 5,
          minEnemyLevel: 1,
          maxEnemyLevel: 1,
        );
      },
    );

    final random = Random();
    if (stage.enemyMonsterIds.isEmpty) {
      print('Error: Stage ${stage.id} has no enemyMonsterIds. Cannot generate enemy.');
      if (_allMonsters.isNotEmpty) {
        return _allMonsters.first;
      }
      throw Exception('No enemy monster IDs defined for stage and no monsters loaded to fallback.');
    }

    final enemyMonsterId = stage.enemyMonsterIds[random.nextInt(stage.enemyMonsterIds.length)];

    final baseEnemy = _allMonsters.firstWhere(
          (m) => m.id == enemyMonsterId,
      orElse: () {
        print('Warning: Enemy monster with ID $enemyMonsterId not found. Using default monster.');
        if (_allMonsters.isNotEmpty) {
          return _allMonsters.first;
        }
        return Monster(
          id: 'default_monster',
          name: '不明なモンスター',
          attribute: MonsterAttribute.none,
          imageUrl: 'assets/images/monsters/default_monster.png',
          maxHp: 50, attack: 10, defense: 5, speed: 5,
          currentExp: 0, level: 1, currentHp: 50, // currentHp も設定
        );
      },
    );

    final int enemyLevel = stage.minEnemyLevel + random.nextInt(stage.maxEnemyLevel - stage.minEnemyLevel + 1);

    return Monster(
      id: baseEnemy.id,
      name: baseEnemy.name,
      imageUrl: baseEnemy.imageUrl,
      attribute: baseEnemy.attribute,
      level: enemyLevel,
      currentHp: (baseEnemy.maxHp * (1 + (enemyLevel - 1) * 0.1)).toInt(),
      maxHp: (baseEnemy.maxHp * (1 + (enemyLevel - 1) * 0.1)).toInt(),
      attack: (baseEnemy.attack * (1 + (enemyLevel - 1) * 0.05)).toInt(),
      defense: (baseEnemy.defense * (1 + (enemyLevel - 1) * 0.05)).toInt(),
      speed: (baseEnemy.speed * (1 + (enemyLevel - 1) * 0.05)).toInt(),
      currentExp: 0,
    );
  }

  List<GachaItem> pullMultipleGacha(int count) {
    List<GachaItem> results = [];
    for (int i = 0; i < count; i++) {
      results.add(pullGacha());
    }
    return results;
  }

  GachaItem pullGacha() {
    if (_gachaPool.isEmpty || _totalWeight == 0) {
      throw Exception('Gacha pool is empty or total weight is zero. Cannot pull. Did you load gacha_pool.json correctly?');
    }

    final random = Random();
    double randomNumber = random.nextDouble() * _totalWeight;

    double currentWeight = 0.0;
    for (var item in _gachaPool) {
      currentWeight += item.weight;
      if (randomNumber < currentWeight) {
        return item;
      }
    }

    print('Warning: Random number did not fall within any weight range. Returning first gacha item as fallback.');
    return _gachaPool.first;
  }

  Monster? getRandomMonsterByAttribute(MonsterAttribute attribute) {
    final List<Monster> filteredMonsters = _allMonsters
        .where((monster) => monster.attribute == attribute)
        .toList();

    if (filteredMonsters.isEmpty) {
      print('Warning: No monsters found for attribute $attribute.');
      return null;
    }

    final random = Random();
    return filteredMonsters[random.nextInt(filteredMonsters.length)];
  }
}