// lib/models/stage.dart
class Stage {
  final String id;
  final String name;
  final String description;
  final List<String> enemyMonsterIds; // このステージで出現する敵モンスターのIDリスト
  final int baseExpAwarded; // このステージをクリアした際に獲得できる基本経験値
  final int minEnemyLevel; // このステージで出現する敵の最小レベル
  final int maxEnemyLevel; // このステージで出現する敵の最大レベル

  Stage({
    required this.id,
    required this.name,
    required this.description,
    required this.enemyMonsterIds,
    this.baseExpAwarded = 10, // デフォルト値を設定
    this.minEnemyLevel = 1, // デフォルト値を設定
    this.maxEnemyLevel = 5, // デフォルト値を設定
  });

  // JSONからStageオブジェクトを生成するファクトリコンストラクタ
  factory Stage.fromJson(Map<String, dynamic> json) {
    // id, name, description, enemyMonsterIds は必須
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final description = json['description'] as String?;
    final enemyMonsterIdsDynamic = json['enemyMonsterIds'] as List<dynamic>?;

    if (id == null || name == null || description == null || enemyMonsterIdsDynamic == null) {
      throw FormatException('Invalid JSON for Stage: missing required fields (id, name, description, enemyMonsterIds)');
    }

    // enemyMonsterIds は List<String> に変換
    final enemyMonsterIds = enemyMonsterIdsDynamic.map((e) => e.toString()).toList();

    return Stage(
      id: id,
      name: name,
      description: description,
      enemyMonsterIds: enemyMonsterIds,
      baseExpAwarded: json['baseExpAwarded'] as int? ?? 10, // JSONになければデフォルト値
      minEnemyLevel: json['minEnemyLevel'] as int? ?? 1, // JSONになければデフォルト値
      maxEnemyLevel: json['maxEnemyLevel'] as int? ?? 5, // JSONになければデフォルト値
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'enemyMonsterIds': enemyMonsterIds,
      'baseExpAwarded': baseExpAwarded,
      'minEnemyLevel': minEnemyLevel,
      'maxEnemyLevel': maxEnemyLevel,
    };
  }
}