import 'package:flutter/foundation.dart'; // ChangeNotifierのために必要

enum MonsterAttribute {
  fire,
  water,
  wood,
  light,
  dark,
  none, // 属性なしの場合
}

// MonsterAttribute の拡張 (displayName ゲッターと属性相性判定メソッド)
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

  // ★ここから属性相性ロジックの追加★
  // 攻撃側 (attackerAttribute) が防御側 (defenderAttribute) に対して
  // どのような相性を持つか判定するメソッド
  // 戻り値:
  //   - 1.5: 効果ばつぐん！ (ダメージ1.5倍)
  //   - 0.5: いまひとつ... (ダメージ0.5倍)
  //   - 1.0: ふつう (ダメージ1.0倍)
  double getAttackMultiplier(MonsterAttribute defenderAttribute) {
    // 三すくみ (火 > 木 > 水 > 火)
    if (this == MonsterAttribute.fire && defenderAttribute == MonsterAttribute.wood) {
      return 1.5; // 炎は木に強い
    } else if (this == MonsterAttribute.wood && defenderAttribute == MonsterAttribute.water) {
      return 1.5; // 木は水に強い
    } else if (this == MonsterAttribute.water && defenderAttribute == MonsterAttribute.fire) {
      return 1.5; // 水は炎に強い
    }
    // 三すくみ (逆相性)
    else if (this == MonsterAttribute.fire && defenderAttribute == MonsterAttribute.water) {
      return 0.5; // 炎は水に弱い
    } else if (this == MonsterAttribute.wood && defenderAttribute == MonsterAttribute.fire) {
      return 0.5; // 木は炎に弱い
    } else if (this == MonsterAttribute.water && defenderAttribute == MonsterAttribute.wood) {
      return 0.5; // 水は木に弱い
    }
    // 光・闇 (互いに弱点、それ以外には等倍)
    else if (this == MonsterAttribute.light && defenderAttribute == MonsterAttribute.dark) {
      return 1.5; // 光は闇に強い
    } else if (this == MonsterAttribute.dark && defenderAttribute == MonsterAttribute.light) {
      return 1.5; // 闇は光に強い
    }
    // ノーマル (他の属性に対して等倍)
    // 例えば、ノーマルは全ての属性に対して等倍とする
    // 特定の相性を追加することも可能ですが、ここではシンプルに等倍。

    // それ以外の組み合わせ (同じ属性同士、ノーマル対その他など) は等倍
    return 1.0;
  }
}
// ★ここまで追加★

class Monster extends ChangeNotifier {
  final String id;
  final String name;
  final MonsterAttribute attribute;
  final String imageUrl;
  final String description;

  int _maxHp;
  int _attack;
  int _defense;
  int _speed;

  int _currentExp;
  int _level;
  int _currentHp;

  int get currentExp => _currentExp;
  int get level => _level;
  int get currentHp => _currentHp;

  int get maxHp => _maxHp;
  int get attack => _attack;
  int get defense => _defense;
  int get speed => _speed;

  set currentHp(int value) {
    if (_currentHp != value) {
      _currentHp = value;
      notifyListeners();
    }
  }

  Monster({
    required this.id,
    required this.name,
    required this.attribute,
    required this.imageUrl,
    this.description = '',
    required int maxHp,
    required int attack,
    required int defense,
    required int speed,
    int currentExp = 0,
    int level = 1,
    required int currentHp,
  }) : _currentExp = currentExp,
        _level = level,
        _currentHp = currentHp,
        _maxHp = maxHp,
        _attack = attack,
        _defense = defense,
        _speed = speed;

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
    return 100 + (_level - 1) * 50; // 例: Lv1→Lv2は100、Lv2→Lv3は150
  }

  void gainExp(int amount) {
    _currentExp += amount;
    debugPrint('${name} が $amount の経験値を獲得しました。現在の経験値: $_currentExp');

    while (_currentExp >= expToNextLevel) {
      _currentExp -= expToNextLevel;
      _level++; // レベルアップ

      _maxHp += 10;
      _attack += 2;
      _defense += 1;
      _speed += 1;

      _currentHp = _maxHp; // レベルアップでHP全回復

      debugPrint('${name} がレベルアップ！ 新しいレベル: $_level');
      debugPrint('新しいステータス: HP:${_maxHp}, 攻撃力:${_attack}, 防御力:${_defense}, スピード:${_speed}');
    }
    notifyListeners(); // 変更をUIに通知
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
    if (_currentHp > _maxHp) {
      _currentHp = _maxHp;
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
      'maxHp': _maxHp,
      'attack': _attack,
      'defense': _defense,
      'speed': _speed,
      'currentExp': _currentExp,
      'level': _level,
      'currentHp': _currentHp,
    };
  }
}