// lib/providers/user_data_provider.dart

import 'package:flutter/foundation.dart';
import 'package:garbage_app/models/user_data.dart';
import 'package:garbage_app/services/user_data_service.dart';
import 'package:garbage_app/models/monster.dart'; // ★ ここを追加 ★

class UserDataProvider with ChangeNotifier {
  UserData _userData = UserData();
  final UserDataService _userDataService = UserDataService();

  UserData get userData => _userData;

  Future<void> loadUserData() async {
    _userData = await _userDataService.loadUserData();
    notifyListeners();
  }

  Future<void> updateGachaTickets(int change) async {
    await _userDataService.updateGachaTickets(change);
    await loadUserData();
  }

  Future<void> updateCoins(int change) async {
    await _userDataService.updateCoins(change);
    await loadUserData();
  }

  // MonsterAttribute 型が認識されるようになる
  Future<void> addMonster(String name, MonsterAttribute attribute, String imageUrl) async {
    await _userDataService.addMonster(name, attribute, imageUrl);
    await loadUserData();
  }
}