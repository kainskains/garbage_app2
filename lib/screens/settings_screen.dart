// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            return _buildGarbageTypeSetting(context, settingsProvider, type);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGarbageTypeSetting(BuildContext context, GarbageCollectionSettings settingsProvider, GarbageType type) {
    final CollectionRule currentRule = settingsProvider.settings[type] ?? CollectionRule();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settingsProvider.getGarbageTypeName(type),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('頻度: ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: DropdownButton<CollectionFrequency>(
                    isExpanded: true,
                    value: currentRule.frequency,
                    items: CollectionFrequency.values.map((frequency) {
                      return DropdownMenuItem(
                        value: frequency,
                        child: Text(settingsProvider.getFrequencyName(frequency)),
                      );
                    }).toList(),
                    onChanged: (CollectionFrequency? newFrequency) {
                      if (newFrequency != null) {
                        settingsProvider.updateCollectionRule(
                          type,
                          CollectionRule(
                            frequency: newFrequency,
                            weekday: currentRule.weekday,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('曜日: ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: DropdownButton<Weekday>(
                    isExpanded: true,
                    value: currentRule.weekday,
                    items: Weekday.values.map((day) {
                      return DropdownMenuItem(
                        value: day,
                        child: Text(settingsProvider.getWeekdayName(day)),
                      );
                    }).toList(),
                    onChanged: (Weekday? newWeekday) {
                      if (newWeekday != null) {
                        settingsProvider.updateCollectionRule(
                          type,
                          CollectionRule(
                            frequency: currentRule.frequency,
                            weekday: newWeekday,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}