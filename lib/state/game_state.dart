import 'package:flutter/material.dart'; // ChangeNotifierを使うため
import 'package:garbage_app/models/monster.dart';
import 'package:garbage_app/models/gacha_item.dart'; // ★GachaItem をインポート★

class GameState extends ChangeNotifier {
  List<Monster> _monsters = [];
  List<GachaItem> _inventory = []; // ★インベントリを追加★
  int _gold = 0; // ★ゴールドを追加★
  int _gachaTickets = 0; // ★ガチャチケットを追加★

  List<Monster> get monsters => _monsters;
  List<GachaItem> get inventory => _inventory; // ★インベントリのゲッター★
  int get gold => _gold; // ★ゴールドのゲッター★
  int get gachaTickets => _gachaTickets; // ★ガチャチケットのゲッター★

  // 初期化（ダミーデータなど）
  GameState() {
    // 例: 初期モンスター
    _monsters.add(
      Monster(
        id: 'player_monster_1',
        name: '初期モンスター',
        attribute: MonsterAttribute.none,
        imageUrl: 'assets/images/monsters/monster_rare_a.png',
        maxHp: 100,
        attack: 10,
        defense: 5,
        speed: 7,
        level: 1,
        currentExp: 0,
        currentHp: 100,
        description: 'あなたの最初の相棒。',
      ),
    );

    // 初期ガチャチケット
    _gachaTickets = 5; // 例: 5枚からスタート
  }

  void addMonster(Monster monster) {
    _monsters.add(monster);
    notifyListeners();
  }

  // ★新しいメソッド: アイテムをインベントリに追加★
  void addInventoryItem(GachaItem item) {
    _inventory.add(item);
    notifyListeners();
  }

  // ★経験値玉を使ってモンスターに経験値を与える（単体使用用、今回は使わないが残しておく）★
  void useExperienceOrb(String monsterId, String orbId) {
    final monsterIndex = _monsters.indexWhere((m) => m.id == monsterId);
    final orbIndex = _inventory.indexWhere((item) => item.id == orbId && item.type == GachaItemType.expOrb);

    if (monsterIndex != -1 && orbIndex != -1) {
      final monster = _monsters[monsterIndex];
      final orb = _inventory[orbIndex];

      if (orb.expValue != null) {
        monster.gainExp(orb.expValue!); // MonsterクラスのgainExpメソッドを呼び出す
        _inventory.removeAt(orbIndex); // インベントリから経験値玉を削除
        notifyListeners();
        print('${monster.name} は ${orb.name} を使って ${orb.expValue} 経験値を獲得しました！');
      } else {
        print('エラー: 経験値玉にexpValueが設定されていません。');
      }
    } else {
      print('エラー: モンスターまたは経験値玉が見つかりません。');
    }
  }

  // ★新しいメソッド: 経験値玉をまとめて使用する★
  void useExperienceOrbBatch(String monsterId, String orbId, int quantity) {
    final monsterIndex = _monsters.indexWhere((m) => m.id == monsterId);

    if (monsterIndex == -1) {
      print('エラー: モンスターが見つかりません。');
      return;
    }

    final monster = _monsters[monsterIndex];
    int totalExpGained = 0;
    int itemsRemoved = 0;

    // 逆順にループして削除してもインデックスが狂わないようにする
    for (int i = _inventory.length - 1; i >= 0 && itemsRemoved < quantity; i--) {
      final item = _inventory[i];
      if (item.id == orbId && item.type == GachaItemType.expOrb && item.expValue != null) {
        totalExpGained += item.expValue!;
        _inventory.removeAt(i);
        itemsRemoved++;
      }
    }

    if (itemsRemoved > 0) {
      monster.gainExp(totalExpGained); // モンスターに合計経験値を与える
      notifyListeners();
      print('${monster.name} は経験値玉を $itemsRemoved 個使って $totalExpGained 経験値を獲得しました！');
    } else {
      print('エラー: 指定された経験値玉が見つからないか、数量が不足しています。');
    }
  }


  // バトル勝利時などに経験値を獲得する既存のメソッド
  void gainExpToMonster(String monsterId, int exp) {
    final monsterIndex = _monsters.indexWhere((m) => m.id == monsterId);
    if (monsterIndex != -1) {
      _monsters[monsterIndex].gainExp(exp);
      notifyListeners();
    }
  }

  // ★新しいメソッド: ゴールドの増減★
  void addGold(int amount) {
    _gold += amount;
    notifyListeners();
  }

  bool spendGold(int amount) {
    if (_gold >= amount) {
      _gold -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }

  // ★新しいメソッド: ガチャチケットの増減★
  void addGachaTickets(int amount) {
    _gachaTickets += amount;
    if (_gachaTickets < 0) {
      _gachaTickets = 0; // Ensure tickets don't go below zero
    }
    notifyListeners();
  }

  Monster? _selectedPlayerMonster;
  Monster? get selectedPlayerMonster => _selectedPlayerMonster;

  void setSelectedPlayerMonster(Monster monster) {
    _selectedPlayerMonster = monster;
    notifyListeners();
  }
}
