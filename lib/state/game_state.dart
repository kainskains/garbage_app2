// lib/state/game_state.dart

import 'package:flutter/foundation.dart';
import 'package:garbage_app/models/monster.dart';

class GameState extends ChangeNotifier {
  List<Monster> _monsters = [];
  List<Monster> get monsters => _monsters;

  int _gachaTickets = 0;
  int get gachaTickets => _gachaTickets;

  GameState() {
    _loadMonsters();
  }

  void addGachaTickets(int amount) {
    _gachaTickets += amount;
    print('ガチャチケットを $amount 枚獲得しました。現在のチケット数: $_gachaTickets');
    notifyListeners();
  }

  void addMonster(Monster newMonster) {
    _monsters.add(newMonster);
    notifyListeners();
  }

  void removeMonster(String monsterId) {
    _monsters.removeWhere((m) => m.id == monsterId);
    notifyListeners();
  }

  // ★追加: 特定のモンスターに経験値を付与するメソッド★
  void gainExpToMonster(String monsterId, int expAmount) {
    final monsterIndex = _monsters.indexWhere((m) => m.id == monsterId);
    if (monsterIndex != -1) {
      _monsters[monsterIndex].gainExp(expAmount); // MonsterクラスのgainExpを呼び出す
      // MonsterクラスのgainExp内でnotifyListeners()が呼ばれるため、ここでは通常不要。
      // ただし、リストの変更（例：モンスターの追加・削除）を伴う場合は、ここでもnotifyListeners()が必要。
      // 今回は既存モンスターのプロパティ変更なので、Monster自身が通知すれば良い。
    } else {
      print('Warning: Monster with ID $monsterId not found to gain exp.');
    }
  }

  Future<void> _loadMonsters() async {
    if (_monsters.isEmpty) {
      // ダミーモンスターの初期化時に currentHp も設定するように修正
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
        currentHp: 100, // ★追加: currentHpも初期化★
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
        currentHp: 120, // ★追加: currentHpも初期化★
      ));
      notifyListeners();
    }
  }

  Monster? _selectedPlayerMonster;
  Monster? get selectedPlayerMonster => _selectedPlayerMonster;

  void setSelectedPlayerMonster(Monster monster) {
    _selectedPlayerMonster = monster;
    notifyListeners();
  }
}