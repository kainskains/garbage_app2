// lib/screens/date_settings_screen.dart (新規作成)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';

class DateSettingsScreen extends StatelessWidget {
  const DateSettingsScreen({super.key});

  // 設定された頻度を決められた順序でソートして文字列リストを返すヘルパーメソッド
  List<String> _getSortedFrequencyNames(Set<CollectionFrequency> frequencies, GarbageCollectionSettings provider) {
    final List<CollectionFrequency> sortedOrder = [
      CollectionFrequency.weekly,
      CollectionFrequency.firstWeek,
      CollectionFrequency.secondWeek,
      CollectionFrequency.thirdWeek,
      CollectionFrequency.fourthWeek,
      CollectionFrequency.fifthWeek,
    ];

    final List<String> sortedNames = [];
    for (var freq in sortedOrder) {
      if (frequencies.contains(freq)) {
        sortedNames.add(provider.getFrequencyName(freq));
      }
    }
    return sortedNames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ごみ収集日設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            '各ごみ収集日の設定',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 各ゴミタイプの日付設定項目を生成
          ...GarbageType.values.map((type) {
            return _buildGarbageTypeDateSetting(context, type);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGarbageTypeDateSetting(BuildContext context, GarbageType type) {
    return Consumer<GarbageCollectionSettings>(
      builder: (context, provider, child) {
        final CollectionRule currentRule = provider.settings[type] ?? CollectionRule.empty();

        final bool isWeeklySelected = currentRule.frequencies.contains(CollectionFrequency.weekly);

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
                // 頻度選択 (複数選択可能)
                ExpansionTile(
                  title: Text('頻度: ${currentRule.frequencies.isEmpty ? '未設定' : _getSortedFrequencyNames(currentRule.frequencies, provider).join(', ')}'),
                  children: [
                    ...[
                      CollectionFrequency.weekly,
                      CollectionFrequency.firstWeek,
                      CollectionFrequency.secondWeek,
                      CollectionFrequency.thirdWeek,
                      CollectionFrequency.fourthWeek,
                      CollectionFrequency.fifthWeek,
                    ].map((frequency) {
                      return CheckboxListTile(
                        title: Text(provider.getFrequencyName(frequency)),
                        value: currentRule.frequencies.contains(frequency),
                        onChanged: (bool? newValue) {
                          if (newValue == null) return;

                          final Set<CollectionFrequency> newFrequencies = Set.from(currentRule.frequencies);

                          if (frequency == CollectionFrequency.weekly) {
                            if (newValue) {
                              newFrequencies.clear();
                              newFrequencies.add(CollectionFrequency.weekly);
                            } else {
                              newFrequencies.remove(CollectionFrequency.weekly);
                            }
                          } else {
                            if (isWeeklySelected) {
                              return;
                            }
                            if (newValue) {
                              newFrequencies.add(frequency);
                            } else {
                              newFrequencies.remove(frequency);
                            }
                          }
                          provider.updateCollectionFrequencies(type, newFrequencies);
                        },
                        enabled: !(isWeeklySelected && frequency != CollectionFrequency.weekly),
                      );
                    }).toList(),
                    // 「設定しない」チェックボックス (頻度と曜日が両方noneの場合)
                    CheckboxListTile(
                      title: const Text('設定しない'),
                      value: currentRule.frequencies.isEmpty && currentRule.weekdays.isEmpty,
                      onChanged: (bool? newValue) {
                        if (newValue == true) {
                          provider.updateCollectionRule(type, CollectionRule.empty());
                        } else {
                          // 未設定解除時、デフォルトのルール（例: 毎週月曜）を設定
                          if (currentRule.frequencies.isEmpty && currentRule.weekdays.isEmpty) {
                            provider.updateCollectionRule(type, CollectionRule(frequencies: {CollectionFrequency.weekly}, weekdays: {Weekday.monday}));
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 曜日選択 (複数選択可能)
                ExpansionTile(
                  title: Text('曜日: ${provider.getWeekdayNames(currentRule.weekdays)}'), // 複数曜日名表示用のヘルパー
                  children: [
                    // Weekday.none を除外して、月曜から日曜までを列挙
                    ...Weekday.values.where((day) => day != Weekday.none).map((weekday) {
                      return CheckboxListTile(
                        title: Text(provider.getWeekdayName(weekday)),
                        value: currentRule.weekdays.contains(weekday),
                        onChanged: (bool? newValue) {
                          if (newValue == null) return;

                          final Set<Weekday> newWeekdays = Set.from(currentRule.weekdays);
                          if (newValue) {
                            newWeekdays.add(weekday);
                          } else {
                            newWeekdays.remove(weekday);
                          }
                          provider.updateCollectionWeekdays(type, newWeekdays);
                        },
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}