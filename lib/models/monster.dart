import 'package:flutter/foundation.dart'; // ChangeNotifierのために必要

// MonsterAttribute の定義は、このファイルの外部にある場合はそのままにしておいてください。
// もし、このファイル内で定義する場合は、以下のようなenumが必要です。
enum MonsterAttribute {
  fire,
  water,
  wood,
  light,
  dark,
  none, // 属性なしの場合
}

// MonsterAttribute の拡張 (displayName ゲッター)
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

  // ★変更点1: ステータスプロパティを final からプライベート変数に変更★
  int _maxHp;
  int _attack;
  int _defense;
  int _speed;

  int _currentExp;
  int _level;
  int _currentHp;

  // ゲッター (プライベート変数へのアクセス用)
  int get currentExp => _currentExp;
  int get level => _level;
  int get currentHp => _currentHp;

  // ★変更点2: 各ステータスへのゲッターを追加 (プライベート変数 _maxHp などへのアクセス用)★
  int get maxHp => _maxHp;
  int get attack => _attack;
  int get defense => _defense;
  int get speed => _speed;

  // currentHp のセッター (既存のまま)
  set currentHp(int value) {
    if (_currentHp != value) {
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
    // ★変更点3: コンストラクタ引数を int 型として受け取る★
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
        _maxHp = maxHp,    // ★変更点4: プライベート変数に割り当てる★
        _attack = attack,
        _defense = defense,
        _speed = speed;

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
      // ★変更点5: fromJson でも int 型として受け取る★
      maxHp: json['maxHp'] as int,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      speed: json['speed'] as int,
      currentExp: json['currentExp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentHp: json['currentHp'] as int? ?? (json['maxHp'] as int),
    );
  }

  // 次のレベルまでの経験値
  int get expToNextLevel {
    return 100 + (_level - 1) * 50; // 例: Lv1→Lv2は100、Lv2→Lv3は150
  }

  // 経験値獲得メソッド
  void gainExp(int amount) {
    _currentExp += amount;
    debugPrint('${name} が $amount の経験値を獲得しました。現在の経験値: $_currentExp'); // printをdebugPrintに変更

    while (_currentExp >= expToNextLevel) {
      _currentExp -= expToNextLevel;
      _level++; // レベルアップ

      // ★変更点6: レベルアップ時のステータス上昇ロジック★
      // ここで各ステータスを増やす
      _maxHp += 10;   // HPを10増やす
      _attack += 2;   // 攻撃力を2増やす
      _defense += 1;  // 防御力を1増やす
      _speed += 1;    // スピードを1増やす (必要であれば)

      _currentHp = _maxHp; // レベルアップでHP全回復

      debugPrint('${name} がレベルアップ！ 新しいレベル: $_level'); // printをdebugPrintに変更
      debugPrint('新しいステータス: HP:${_maxHp}, 攻撃力:${_attack}, 防御力:${_defense}, スピード:${_speed}'); // printをdebugPrintに変更
    }
    notifyListeners(); // 変更をUIに通知
  }

  // ダメージを受けるメソッド
  void takeDamage(int damage) {
    _currentHp -= damage;
    if (_currentHp < 0) {
      _currentHp = 0;
    }
    notifyListeners();
  }

  // HPを回復するメソッド
  void heal(int amount) {
    _currentHp += amount;
    if (_currentHp > _maxHp) { // 最大HPを超えないように修正
      _currentHp = _maxHp;
    }
    notifyListeners();
  }

  // Monster オブジェクトをJSON（Map）に変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'attribute': attribute.toString().split('.').last,
      'imageUrl': imageUrl,
      'description': description,
      // ★変更点7: プライベート変数を参照してJSONに変換★
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