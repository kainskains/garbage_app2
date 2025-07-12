import 'package:garbage_app/models/monster.dart'; // MonsterAttributeを使うため

// GachaItemのタイプを定義するenum
enum GachaItemType {
  monster, // モンスター
  expOrb,  // 経験値玉
  gold,    // ゴールド
  ticket,  // ガチャチケット (★ここが重要です★)
  item     // その他のアイテム
}

// ガチャから排出されるアイテムのモデル
class GachaItem {
  final String id; // アイテムの一意なID (モンスターIDと異なる場合もある)
  final String name; // アイテムの名前 (例: "レアモンスター", "ガチャチケット5枚")
  final GachaItemType type; // アイテムのタイプ (例: 'monster', 'ticket', 'item')
  final double weight; // ガチャ排出の重み (確率計算用)
  final String? monsterId; // typeが'monster'の場合のモンスターのID
  final MonsterAttribute? monsterAttribute; // モンスターの場合の属性
  final int? expValue; // 経験値玉の場合の経験値量
  final int? goldValue; // ゴールドの場合の量
  final int? ticketAmount; // ガチャチケットの場合の枚数 (★ここが重要です★)
  final String? imageUrl; // アイテムの画像パス (インベントリ表示に対応)
  final String? description; // アイテムの説明

  GachaItem({
    required this.id,
    required this.name,
    required this.type,
    required this.weight,
    this.monsterId,
    this.monsterAttribute,
    this.expValue,
    this.goldValue,
    this.ticketAmount, // ★コンストラクタに追加★
    this.imageUrl,
    this.description,
  });

  // JSONからのファクトリーコンストラクタ
  factory GachaItem.fromJson(Map<String, dynamic> json) {
    return GachaItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: GachaItemType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => GachaItemType.item, // 未知のタイプの場合のデフォルト
      ),
      weight: (json['weight'] as num).toDouble(),
      monsterId: json['monsterId'] as String?,
      monsterAttribute: json['monsterAttribute'] != null
          ? MonsterAttribute.values.firstWhere(
            (e) => e.toString().split('.').last == json['monsterAttribute'],
        orElse: () => MonsterAttribute.none, // 未知の属性の場合のデフォルト
      )
          : null,
      expValue: json['expValue'] as int?,
      goldValue: json['goldValue'] as int?,
      ticketAmount: json['ticketAmount'] as int?, // ★fromJson に追加★
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
    );
  }

  // GachaItemをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'weight': weight,
      'monsterId': monsterId,
      'monsterAttribute': monsterAttribute?.toString().split('.').last,
      'expValue': expValue,
      'goldValue': goldValue,
      'ticketAmount': ticketAmount, // ★toJson に追加★
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}