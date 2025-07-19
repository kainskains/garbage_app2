// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart'; // 新しく追加

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // GarbageCollectionSettingsProvider を監視
    final settingsProvider = Provider.of<GarbageCollectionSettings>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'ごみ収集日設定',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 各ゴミタイプの設定項目を生成
          ...GarbageType.values.map((type) {
            // 'none' 以外のWeekday値を取得
            final availableWeekdays = Weekday.values.where((day) => day != Weekday.none).toList();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      settingsProvider.getGarbageTypeName(type),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: DropdownButton<Weekday>(
                      isExpanded: true,
                      value: settingsProvider.settings[type],
                      items: [
                        // 未設定オプションを最初に追加
                        DropdownMenuItem(
                          value: Weekday.none,
                          child: Text(settingsProvider.getWeekdayName(Weekday.none)),
                        ),
                        // その他の曜日オプション
                        ...availableWeekdays.map((day) => DropdownMenuItem(
                          value: day,
                          child: Text(settingsProvider.getWeekdayName(day)),
                        )).toList(),
                      ],
                      onChanged: (Weekday? newValue) {
                        if (newValue != null) {
                          settingsProvider.updateCollectionDay(type, newValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}