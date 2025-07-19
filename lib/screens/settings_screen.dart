// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            return _buildGarbageTypeSetting(context, type);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGarbageTypeSetting(BuildContext context, GarbageType type) {
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
                  // ★ここを修正: ヘルパーメソッドを使用してソートされた文字列を生成★
                  title: Text('頻度: ${currentRule.frequencies.isEmpty ? '未設定' : _getSortedFrequencyNames(currentRule.frequencies, provider).join(', ')}'),
                  children: [
                    // ここは以前の修正で既にソート済み
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
                    // 「設定しない」チェックボックス
                    CheckboxListTile(
                      title: const Text('設定しない'),
                      value: currentRule.frequencies.isEmpty && currentRule.weekday == Weekday.none,
                      onChanged: (bool? newValue) {
                        if (newValue == true) {
                          provider.updateCollectionRule(type, CollectionRule.empty());
                        } else {
                          if (currentRule.frequencies.isEmpty && currentRule.weekday == Weekday.none) {
                            provider.updateCollectionRule(type, CollectionRule(frequencies: {CollectionFrequency.weekly}, weekday: Weekday.monday));
                          } else if (currentRule.frequencies.isNotEmpty && currentRule.weekday == Weekday.none) {
                            provider.updateCollectionWeekday(type, Weekday.monday);
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 曜日選択 (単一選択)
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
                            child: Text(provider.getWeekdayName(day)),
                          );
                        }).toList(),
                        onChanged: (Weekday? newWeekday) {
                          if (newWeekday != null) {
                            if (currentRule.frequencies.isEmpty && currentRule.weekday == Weekday.none) {
                              provider.updateCollectionRule(type, CollectionRule(frequencies: {CollectionFrequency.weekly}, weekday: newWeekday));
                            } else {
                              provider.updateCollectionWeekday(type, newWeekday);
                            }
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
      },
    );
  }
}