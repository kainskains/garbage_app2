// lib/screens/time_settings_screen.dart (新規作成)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';

class TimeSettingsScreen extends StatelessWidget {
  const TimeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ごみ収集時間設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            '各ごみ収集時間の設定',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 各ゴミタイプの時間設定項目を生成
          ...GarbageType.values.map((type) {
            return _buildGarbageTypeTimeSetting(context, type);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGarbageTypeTimeSetting(BuildContext context, GarbageType type) {
    return Consumer<GarbageCollectionSettings>(
      builder: (context, provider, child) {
        final CollectionRule currentRule = provider.settings[type] ?? CollectionRule.empty();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.getGarbageTypeName(type),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // 時間設定
                ListTile(
                  title: const Text('収集時間'),
                  subtitle: Text(currentRule.timeOfDay ?? '未設定'),
                  trailing: currentRule.timeOfDay != null
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      provider.updateCollectionTime(type, null); // 時間をクリア
                    },
                  )
                      : null,
                  onTap: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: currentRule.timeOfDay != null
                          ? TimeOfDay(
                        hour: int.parse(currentRule.timeOfDay!.split(':')[0]),
                        minute: int.parse(currentRule.timeOfDay!.split(':')[1]),
                      )
                          : TimeOfDay.now(),
                      builder: (BuildContext context, Widget? child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), // 24時間表示に固定
                          child: child!,
                        );
                      },
                    );
                    if (pickedTime != null) {
                      final String formattedTime = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                      provider.updateCollectionTime(type, formattedTime);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}