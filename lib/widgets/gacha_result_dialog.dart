// lib/widgets/gacha_result_dialog.dart

import 'package:flutter/material.dart';
import 'package:garbage_app/models/monster.dart'; // Monsterモデルをインポート

class GachaResultDialog extends StatelessWidget {
  final Monster obtainedMonster; // 獲得したモンスター

  const GachaResultDialog({
    super.key,
    required this.obtainedMonster,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.deepPurple[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'ガチャ結果！',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'おめでとうございます！',
              style: TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 10),
            Text(
              obtainedMonster.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.redAccent,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Color.fromARGB(100, 0, 0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // モンスター画像 (MonsterオブジェクトのimageUrlが正しいパスを持つ前提)
            ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: obtainedMonster.imageUrl.isNotEmpty
                  ? Image.asset(
                obtainedMonster.imageUrl,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 180, color: Colors.grey);
                },
              )
                  : const Icon(Icons.help_outline, size: 180, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              'Lv.${obtainedMonster.level} / 属性: ${obtainedMonster.attribute.displayName}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '閉じる',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}