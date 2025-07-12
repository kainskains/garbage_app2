import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/monster.dart';

class MonsterDetailScreen extends StatelessWidget {
  final Monster monster; // 表示するモンスターオブジェクトを受け取る

  const MonsterDetailScreen({
    super.key,
    required this.monster, // コンストラクタでモンスターを受け取る
  });

  // 属性を日本語に変換するヘルパーメソッド (MonsterAttributeExtensionを使っても良い)
  // 現状のコードに合わせ、ローカルメソッドとして残します。
  String _getAttributeJapaneseName(MonsterAttribute attribute) {
    switch (attribute) {
      case MonsterAttribute.fire:
        return '火属性';
      case MonsterAttribute.water:
        return '水属性';
      case MonsterAttribute.wood:
        return '木属性';
      case MonsterAttribute.light:
        return '光属性';
      case MonsterAttribute.dark:
        return '闇属性';
      case MonsterAttribute.none:
        return 'ノーマル属性';
    // default: return '不明'; // 全てのケースを網羅していれば不要
    }
  }

  @override
  Widget build(BuildContext context) {
    // ★ここを修正★: 受け取った monster オブジェクトを ChangeNotifierProvider で提供する
    return ChangeNotifierProvider<Monster>.value( // .value コンストラクタを使う
      value: monster, // この monster オブジェクトをProviderとして提供
      child: Scaffold(
        appBar: AppBar(
          title: Text(monster.name), // モンスター名をAppBarのタイトルにする
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          // 内容が画面に収まらない場合にスクロール可能にする
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // 中央揃え
              children: [
                // モンスター画像
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0), // 角丸を大きく
                  child: monster.imageUrl.isNotEmpty
                      ? Image.asset(
                    monster.imageUrl,
                    width: 200, // 大きめの画像サイズ
                    height: 200,
                    fit: BoxFit.contain, // 画像全体を表示
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image,
                          size: 200, color: Colors.grey);
                    },
                  )
                      : const Icon(Icons.help_outline,
                      size: 200, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // モンスター名とレベル
                Text(
                  monster.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                // Consumer<Monster> はこの ChangeNotifierProvider の子孫として配置されているのでOK
                Consumer<Monster>(
                  builder: (context, monster, child) {
                    final double expRatio = monster.expToNextLevel > 0
                        ? monster.currentExp / monster.expToNextLevel
                        : 0.0;
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Lv.${monster.level} / ${_getAttributeJapaneseName(monster.attribute)}',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 16),

                        // ステータス表示
                        _buildStatRow(context, Icons.favorite, 'HP',
                            monster.currentHp, monster.maxHp, Colors.red),
                        _buildStatRow(context, Icons.gavel, '攻撃', monster.attack,
                            null, Colors.blue),
                        _buildStatRow(context, Icons.shield, '防御', monster.defense,
                            null, Colors.brown),
                        _buildStatRow(context, Icons.speed, '素早さ', monster.speed,
                            null, Colors.purple),

                        const SizedBox(height: 20),

                        // 経験値バー
                        if (monster.level < 100) // レベル上限に応じて表示
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXP: ${monster.currentExp} / ${monster.expToNextLevel}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: expRatio,
                                backgroundColor: Colors.grey[300],
                                color: Colors.amber,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // 説明文
                Text(
                  monster.description.isNotEmpty
                      ? monster.description
                      : 'このモンスターにはまだ説明文がありません。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
                const SizedBox(height: 20),

                // デバッグ用: 経験値獲得ボタン (Consumer の外に出し、Provider.of を使う)
                ElevatedButton(
                  onPressed: () {
                    // Consumer の外から Monster インスタンスにアクセスする場合
                    // listen: false を指定することで、このボタンがMonsterの変更をリッスンして再ビルドされるのを防ぐ
                    Provider.of<Monster>(context, listen: false).gainExp(50);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text('経験値獲得 (テスト用)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ステータス行を構築するヘルパーウィジェット
  Widget _buildStatRow(BuildContext context, IconData icon, String label,
      int currentValue, int? maxValue, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // 中央揃え
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 80, // ラベルの幅を固定して揃える
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            maxValue != null ? '$currentValue / $maxValue' : '$currentValue',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}