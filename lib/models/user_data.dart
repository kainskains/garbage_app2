// lib/models/user_data.dart

import 'package:garbage_app/models/monster.dart'; // MonsterとMonsterAttributeのインポート

class UserData {
  int gachaTickets;
  int currentCoins;
  List<Monster> ownedMonsters; // ユーザーが所有するモンスターのリスト
  // 他にもユーザーが持つアイテムや情報などがあればここに追加

  UserData({
    this.gachaTickets = 0,
    this.currentCoins = 0,
    List<Monster>? ownedMonsters,
  }) : ownedMonsters = ownedMonsters ?? [];

  // JSONからUserDataオブジェクトを生成するファクトリコンストラクタ
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      gachaTickets: json['gachaTickets'] as int? ?? 0,
      currentCoins: json['currentCoins'] as int? ?? 0,
      ownedMonsters: (json['ownedMonsters'] as List<dynamic>?)
          ?.map((mJson) => Monster.fromJson(mJson as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  // UserDataオブジェクトをJSONに変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'gachaTickets': gachaTickets,
      'currentCoins': currentCoins,
      'ownedMonsters': ownedMonsters.map((m) => m.toJson()).toList(),
    };
  }

  // データのコピーを作成するヘルパーメソッド（Providerで変更通知を効率的に行うため）
  UserData copyWith({
    int? gachaTickets,
    int? currentCoins,
    List<Monster>? ownedMonsters,
  }) {
    return UserData(
      gachaTickets: gachaTickets ?? this.gachaTickets,
      currentCoins: currentCoins ?? this.currentCoins,
      ownedMonsters: ownedMonsters ?? this.ownedMonsters,
    );
  }
}