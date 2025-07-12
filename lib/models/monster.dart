// lib/models/monster.dart

import 'package:flutter/foundation.dart'; // ChangeNotifierのために必要

enum MonsterAttribute {
  fire,
  water,
  wood,
  light,
  dark,
  none, // 属性なしの場合
}

// ★追加: MonsterAttribute の拡張 (displayName ゲッター)★
extension MonsterAttributeExtension on MonsterAttribute {
  String get displayName {
    switch (this) {
      case MonsterAttribute.fire:
        return '炎';
      case MonsterAttribute.water:
        return '水';
      case MonsterAttribute.wood:
        return '木';
      case MonsterAttribute.light:
        return '光';
      case MonsterAttribute.dark:
        return '闇';
      case MonsterAttribute.none:
        return 'なし';
    }
  }
}


class Monster extends ChangeNotifier {
  final String id;
  final String name;
  final MonsterAttribute attribute;
  final String imageUrl;
  final String description;
  final int maxHp;
  final int attack;
  final int defense;
  final int speed;

  int _currentExp;
  int _level;
  int _currentHp;

  // ゲッター
  int get currentExp => _currentExp;
  int get level => _level;
  int get currentHp => _currentHp;

  // ★追加: currentHp のセッター★
  set currentHp(int value) {
    if (_currentHp != value) { // 値が変わった場合のみ更新と通知
      _currentHp = value;
      notifyListeners();
    }
  }


  // コンストラクタ
  Monster({
    required this.id,
    required this.name,
    required this.attribute,
    required this.imageUrl,
    this.description = '',
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.speed,
    int currentExp = 0,
    int level = 1,
    required int currentHp,
  }) : _currentExp = currentExp,
        _level = level,
        _currentHp = currentHp;

  // JSONからのファクトリーコンストラクタ
  factory Monster.fromJson(Map<String, dynamic> json) {
    return Monster(
      id: json['id'] as String,
      name: json['name'] as String,
      attribute: MonsterAttribute.values.firstWhere(
            (e) => e.toString().split('.').last == json['attribute'],
        orElse: () => MonsterAttribute.none,
      ),
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String? ?? '',
      maxHp: json['maxHp'] as int,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      speed: json['speed'] as int,
      currentExp: json['currentExp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentHp: json['currentHp'] as int? ?? (json['maxHp'] as int),
    );
  }

  int get expToNextLevel {
    return 100 + (_level - 1) * 50;
  }

  void gainExp(int amount) {
    _currentExp += amount;
    print('${name} が $amount の経験値を獲得しました。現在の経験値: $_currentExp');

    while (_currentExp >= expToNextLevel) {
      _currentExp -= expToNextLevel;
      _level++;
      _currentHp = maxHp; // レベルアップでHP全回復
      print('${name} がレベルアップ！ 新しいレベル: $_level');
      // 必要に応じて、ステータスをレベルに応じて増加させるロジックを追加
      // 例: maxHp += 10; attack += 2; など
    }
    notifyListeners();
  }

  void takeDamage(int damage) {
    _currentHp -= damage;
    if (_currentHp < 0) {
      _currentHp = 0;
    }
    notifyListeners();
  }

  void heal(int amount) {
    _currentHp += amount;
    if (_currentHp > maxHp) {
      _currentHp = maxHp;
    }
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'attribute': attribute.toString().split('.').last,
      'imageUrl': imageUrl,
      'description': description,
      'maxHp': maxHp,
      'attack': attack,
      'defense': defense,
      'speed': speed,
      'currentExp': _currentExp,
      'level': _level,
      'currentHp': _currentHp,
    };
  }
}