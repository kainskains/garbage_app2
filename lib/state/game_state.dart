// lib/state/game_state.dart

import 'package:flutter/foundation.dart'; // ChangeNotifierのために必要
import 'package:garbage_app/models/monster.dart'; // Monsterモデルをインポート

class GameState extends ChangeNotifier {
  List<Monster> _monsters = [];
  List<Monster> get monsters => _monsters;

  int _gachaTickets = 0; // ガチャチケットの数を管理するプロパティ
  int get gachaTickets => _gachaTickets; // ガチャチケットのゲッター

  // ガチャチケットを追加するメソッド
  void addGachaTickets(int amount) {
    _gachaTickets += amount;
    print('ガチャチケットを $amount 枚獲得しました。現在のチケット数: $_gachaTickets');
    notifyListeners(); // UIを更新するために通知
  }

  // コンストラクタで初期データをロードするなどの処理が必要であれば追加
  GameState() {
    _loadMonsters(); // 例えば、UserDataServiceからモンスターをロード
  }

  // ここにモンスターを追加するメソッド（UserDatServiceから呼ばれる）
  void addMonster(Monster newMonster) {
    _monsters.add(newMonster);
    notifyListeners(); // リストが変更されたことを通知
  }

  // モンスターを削除するメソッド（必要に応じて）
  void removeMonster(String monsterId) {
    _monsters.removeWhere((m) => m.id == monsterId);
    notifyListeners();
  }

  // 経験値獲得メソッド（MonsterクラスのgainExpを呼び出す）
  void gainExpToMonster(String monsterId, int expAmount) {
    final monsterIndex = _monsters.indexWhere((m) => m.id == monsterId);
    if (monsterIndex != -1) {
      _monsters[monsterIndex].gainExp(expAmount);
      // notifyListeners() は Monster クラスの gainExp メソッド内で呼ばれる
      // ので、ここでは通常不要。もしモンスターリスト自体が変わったことを通知する
      // 必要がある場合のみ追加。
      // notifyListeners();
    }
  }

  // 保存済みのモンスターをロードするダミーメソッド（UserDatServiceからロードする想定）
  // 実際にはUserDataServiceを使ってShared Preferencesなどからロードします
  Future<void> _loadMonsters() async {
    // 例: 仮のモンスターを追加 (初期起動時にデータがない場合など)
    if (_monsters.isEmpty) {
      _monsters.add(Monster(
        id: 'monster_001',
        name: 'ダミーモンスター1',
        attribute: MonsterAttribute.fire,
        imageUrl: 'assets/images/monsters/monster_rare_a.png',
        maxHp: 100,
        attack: 20,
        defense: 10,
        speed: 15,
        level: 1,
        currentExp: 0,
        currentHp: 100,
      ));
      _monsters.add(Monster(
        id: 'monster_002',
        name: 'ダミーモンスター2',
        attribute: MonsterAttribute.water,
        imageUrl: 'assets/images/monsters/monster_rare_a.png',
        maxHp: 120,
        attack: 18,
        defense: 12,
        speed: 13,
        level: 1,
        currentExp: 0,
        currentHp: 120,
      ));
      notifyListeners();
    }
  }

  // プレイヤーが選択中のモンスターを保存するプロパティ（必要に応じて）
  Monster? _selectedPlayerMonster;
  Monster? get selectedPlayerMonster => _selectedPlayerMonster;

  void setSelectedPlayerMonster(Monster monster) {
    _selectedPlayerMonster = monster;
    notifyListeners();
  }

// TODO: 他のゲーム状態（コイン、アイテムなど）もここに追加可能
}