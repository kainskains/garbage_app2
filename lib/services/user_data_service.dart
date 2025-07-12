// lib/services/user_data_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garbage_app/models/user_data.dart';
import 'package:garbage_app/models/monster.dart'; // MonsterAttributeを使うためインポート

class UserDataService {
  static const String _userDataKey = 'userData';

  // データを保存する
  Future<void> saveUserData(UserData userData) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(userData.toJson());
    await prefs.setString(_userDataKey, jsonString);
    print('Game state saved.');
  }

  // データをロードする
  Future<UserData> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_userDataKey);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        final userData = UserData.fromJson(jsonMap);
        print('Game state loaded.');
        return userData;
      } catch (e) {
        print('Error decoding user data from JSON: $e');
        // JSONが破損している場合などはデフォルトデータを返す
        return UserData();
      }
    }
    print('No saved game state found. Creating new data.');
    return UserData(); // データがなければ新規作成
  }

  // ガチャチケットを更新
  Future<void> updateGachaTickets(int change) async {
    UserData userData = await loadUserData();
    userData = userData.copyWith(gachaTickets: userData.gachaTickets + change);
    await saveUserData(userData);
  }

  // コインを更新 (必要であれば)
  Future<void> updateCoins(int change) async {
    UserData userData = await loadUserData();
    userData = userData.copyWith(currentCoins: userData.currentCoins + change);
    await saveUserData(userData);
  }

  // モンスターを追加
  Future<void> addMonster(String name, MonsterAttribute attribute, String imageUrl) async {
    UserData userData = await loadUserData();
    final newMonster = Monster(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // ユニークなIDを生成
      name: name,
      attribute: attribute,
      imageUrl: imageUrl,
      maxHp: 100, // 仮の初期ステータス
      attack: 20,
      defense: 10,
      speed: 15,
      level: 1,
      currentExp: 0,

    );
    final updatedMonsters = List<Monster>.from(userData.ownedMonsters)..add(newMonster);
    userData = userData.copyWith(ownedMonsters: updatedMonsters);
    await saveUserData(userData);
    print('Added monster: ${newMonster.name}');
  }

  // ユーザーが持っているモンスターを取得
  Future<List<Monster>> getOwnedMonsters() async {
    UserData userData = await loadUserData();
    return userData.ownedMonsters;
  }
}