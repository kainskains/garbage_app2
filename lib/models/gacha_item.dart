// lib/models/gacha_item.dart (この内容で上書きしてください)

class GachaItem {
  final String id; // アイテムの一意なID (モンスターIDと異なる場合もある)
  final String name; // アイテムの名前 (例: "レアモンスター", "ガチャチケット5枚")
  final String type; // アイテムのタイプ (例: 'monster', 'ticket', 'item')
  final String? monsterId; // typeが'monster'の場合のモンスターのID
  final int? ticketAmount; // typeが'ticket'の場合のチケット枚数
  final double weight; // ガチャ排出の重み

  GachaItem({
    required this.id,
    required this.name,
    required this.type,
    this.monsterId,
    this.ticketAmount,
    required this.weight,
  });

  // JSONからのファクトリーコンストラクタ (GachaServiceで使う)
  factory GachaItem.fromJson(Map<String, dynamic> json) {
    return GachaItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      monsterId: json['monsterId'] as String?,
      ticketAmount: json['ticketAmount'] as int?,
      weight: (json['weight'] as num).toDouble(),
    );
  }

  // GachaItemをJSONに変換 (データ保存が必要な場合)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'monsterId': monsterId,
      'ticketAmount': ticketAmount,
      'weight': weight,
    };
  }
}