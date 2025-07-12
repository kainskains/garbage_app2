// lib/models/monster.dart

import 'package:flutter/foundation.dart';

// モンスターの属性を定義 (plant -> wood に戻す)
enum MonsterAttribute {
  fire('炎'),
  water('水'),
  wood('木'), // ★ plant を wood に修正 ★
  light('光'),
  dark('闇'),
  none('なし'); // normal -> none に修正

  final String displayName;
  const MonsterAttribute(this.displayName);
}

class Monster with ChangeNotifier {
  final String id;
  final String name;
  final MonsterAttribute attribute;
  final String imageUrl;
  final int maxHp;
  final int attack;
  final int defense;
  final int speed;
  int level;
  int _currentHp; // 現在のHP
  int _currentExp; // ★ 追加: 現在の経験値
  int _expToNextLevel; // ★ 追加: 次のレベルまでの経験値

  // TODO: MP関連のプロパティをここに追加する
  // final int maxMp;
  // int _currentMp;


  Monster({
    required this.id,
    required this.name,
    required this.attribute,
    required this.imageUrl,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.speed,
    this.level = 1,
    int? currentHp, // コンストラクタでcurrentHpを受け取れるようにする（UserDataService, GachaServiceのため）
    int? currentExp, // ★ 追加: コンストラクタでcurrentExpを受け取れるようにする
  }) : _currentHp = currentHp ?? maxHp, // currentHpが指定されなければmaxHp
        _currentExp = currentExp ?? 0, // currentExpが指定されなければ0
        _expToNextLevel = _calculateExpToNextLevel(level); // ★ 追加: 初期化時に計算

  // currentHp のゲッターとセッター
  int get currentHp => _currentHp;
  set currentHp(int value) {
    if (_currentHp != value) {
      _currentHp = value.clamp(0, maxHp);
      notifyListeners();
    }
  }

  // currentExp のゲッターとセッター
  int get currentExp => _currentExp;
  set currentExp(int value) {
    if (_currentExp != value) {
      _currentExp = value;
      // レベルアップ判定のために notifyListeners() は gainExp で呼ぶ
      // notifyListeners(); // 個別のsetterでの通知はgainExpに任せる
    }
  }

  // expToNextLevel のゲッター
  int get expToNextLevel => _expToNextLevel; // finalなのでセッターは不要

  // 経験値を獲得するメソッド
  void gainExp(int expAmount) {
    _currentExp += expAmount;
    print('$name が $expAmount 経験値を獲得しました。現在のEXP: $_currentExp');
    while (_currentExp >= _expToNextLevel) { // 複数のレベルアップに対応
      _currentExp -= _expToNextLevel;
      levelUp(); // レベルアップ処理
    }
    notifyListeners(); // 経験値またはレベルが変更されたことをUIに通知
  }

  // ダメージを受けるメソッド
  void takeDamage(int damage) {
    currentHp -= damage; // currentHp のセッターが呼ばれる
    print('$name が $damage ダメージを受けました。現在のHP: $currentHp');
  }

  // HPを回復するメソッド
  void heal(int amount) {
    currentHp += amount; // currentHp のセッターが呼ばれる
    print('$name が $amount 回復しました。現在のHP: $currentHp');
  }

  // レベルアップ処理
  void levelUp() {
    level++;
    _currentHp = maxHp; // レベルアップでHPは満タン回復
    // _expToNextLevel は final なので、新しい Monster インスタンスを生成するか、
    // または _expToNextLevel も変更可能にするか、ロジックを検討する必要がある
    // 今回はシンプルに、次のレベルまでの経験値も計算し直すが、_expToNextLevel は final なので、
    // 実際には新しい Monster インスタンスを生成して置き換える必要がある。
    // しかし、このMonsterインスタンスを使い続ける前提なので、_expToNextLevel を final から外すか、
    // または Monster自体を immutable にしてGameStateで置き換える形にするのが望ましい。
    // 一旦、ここでは _expToNextLevel を final から外します。

    // final _expToNextLevel を int _expToNextLevel に変更しました。
    _expToNextLevel = _calculateExpToNextLevel(level); // 次のレベルまでの経験値を更新

    print('$name がレベルアップしました！現在のレベル: $level, 次のレベルまで: $_expToNextLevel EXP');
    // notifyListeners() は gainExp で呼ぶ
  }

  // 次のレベルまでの経験値を計算するヘルパー関数
  static int _calculateExpToNextLevel(int level) {
    // 簡易的な計算式、必要に応じて調整
    return 100 + (level - 1) * 50;
  }

  // JSONからMonsterオブジェクトを生成するファクトリコンストラクタ
  factory Monster.fromJson(Map<String, dynamic> json) {
    return Monster(
      id: json['id'] as String,
      name: json['name'] as String,
      attribute: MonsterAttribute.values.firstWhere(
            (e) => e.toString() == 'MonsterAttribute.${json['attribute'] as String}',
        orElse: () => MonsterAttribute.none, // normal を none に変更
      ),
      imageUrl: json['imageUrl'] as String,
      maxHp: json['maxHp'] as int,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      speed: json['speed'] as int,
      level: json['level'] as int? ?? 1,
      currentHp: json['currentHp'] as int?, // JSONからcurrentHpも読み込めるように
      currentExp: json['currentExp'] as int?, // ★ 追加: JSONからcurrentExpも読み込めるように
    );
  }

  // MonsterオブジェクトをJSONに変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'attribute': attribute.toString().split('.').last,
      'imageUrl': imageUrl,
      'maxHp': maxHp,
      'attack': attack,
      'defense': defense,
      'speed': speed,
      'level': level,
      'currentHp': _currentHp,
      'currentExp': _currentExp, // ★ 追加: 現在の経験値も保存
    };
  }
}