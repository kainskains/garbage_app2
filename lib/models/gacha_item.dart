// lib/models/gacha_item.dart
import 'package:garbage_app/models/monster.dart'; // MonsterAttributeを使うためにインポート

class GachaItem {
  final String name;
  final String? imageUrl; // アイテムの画像パス (モンスターの場合)
  final bool isMonster; // モンスターかどうか
  final int ticketAmount; // チケットの場合の量
  final MonsterAttribute? attribute; // モンスターの場合の属性
  final double weight; // ガチャ排出の重み (確率)

  GachaItem({
    required this.name,
    this.imageUrl,
    required this.isMonster,
    this.ticketAmount = 0,
    this.attribute,
    required this.weight, // weightを必須にする
  });

  // チケットアイテムのファクトリーコンストラクタ
  factory GachaItem.ticket({required int amount, required double weight}) {
    return GachaItem(
      name: '$amount ガチャチケット',
      isMonster: false,
      ticketAmount: amount,
      weight: weight,
    );
  }

  // モンスターアイテムのファクトリーコンストラクタ
  factory GachaItem.monster({
    required String name,
    required String imageUrl,
    required MonsterAttribute attribute,
    required double weight,
  }) {
    return GachaItem(
      name: name,
      imageUrl: imageUrl,
      isMonster: true,
      attribute: attribute,
      weight: weight,
    );
  }

  // JSONからGachaItemを生成するためのファクトリーコンストラクタ
  factory GachaItem.fromJson(Map<String, dynamic> json) {
    // 必須フィールドのチェック
    final name = json['name'] as String?;
    final isMonster = json['isMonster'] as bool?;
    final weight = (json['weight'] as num?)?.toDouble();

    if (name == null || isMonster == null || weight == null) {
      throw FormatException('Invalid JSON for GachaItem: missing required fields (name, isMonster, weight)');
    }

    if (isMonster) {
      final imageUrl = json['imageUrl'] as String?;
      final attributeString = json['attribute'] as String?;
      if (imageUrl == null || attributeString == null) {
        throw FormatException('Invalid JSON for Monster GachaItem: missing imageUrl or attribute');
      }
      return GachaItem.monster(
        name: name,
        imageUrl: imageUrl,
        attribute: MonsterAttribute.values.firstWhere(
              (e) => e.toString() == 'MonsterAttribute.$attributeString',
          orElse: () => MonsterAttribute.none, // デフォルト値
        ),
        weight: weight,
      );
    } else {
      final ticketAmount = json['ticketAmount'] as int?;
      if (ticketAmount == null) {
        throw FormatException('Invalid JSON for Ticket GachaItem: missing ticketAmount');
      }
      return GachaItem.ticket(
        amount: ticketAmount,
        weight: weight,
      );
    }
  }
}