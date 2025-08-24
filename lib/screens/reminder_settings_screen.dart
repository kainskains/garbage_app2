// lib/screens/reminder_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';
import 'package:garbage_app/models/garbage_type.dart';

class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ごみ収集リマインダー設定'),
      ),
      body: Consumer<GarbageCollectionSettings>(
        builder: (context, provider, child) {
          // ゴミ種類が空の場合
          if (provider.garbageTypes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'まだゴミの種類が追加されていません。\n右下のボタンから新しいゴミを追加してください。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        provider.resetGarbageTypes(); // 初期ゴミリストに戻す
                      },
                      child: const Text('初期項目に戻す'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ゴミ種類が存在する場合のリスト表示
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.garbageTypes.length,
            itemBuilder: (context, index) {
              final GarbageType type = provider.garbageTypes[index];
              return _buildGarbageTypeReminderSetting(context, provider, type);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGarbageTypeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getSortedFrequencyNames(
      Set<CollectionFrequency> frequencies, GarbageCollectionSettings provider) {
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
    return sortedNames.join(', ');
  }

  Widget _buildGarbageTypeReminderSetting(
      BuildContext context, GarbageCollectionSettings provider, GarbageType type) {
    final CollectionRule currentRule =
        provider.settings[type.type] ?? CollectionRule.empty();
    final bool isWeeklySelected =
    currentRule.frequencies.contains(CollectionFrequency.weekly);
    final bool isRuleEmpty =
        currentRule.frequencies.isEmpty && currentRule.weekdays.isEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル + 削除ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  type.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    provider.removeGarbageType(type.type);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 頻度設定
            ExpansionTile(
              title: Text(
                  '頻度: ${isRuleEmpty ? '設定しない' : _getSortedFrequencyNames(currentRule.frequencies, provider)}'),
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
                      final Set<CollectionFrequency> newFrequencies =
                      Set.from(currentRule.frequencies);

                      if (frequency == CollectionFrequency.weekly) {
                        if (newValue) {
                          newFrequencies.clear();
                          newFrequencies.add(CollectionFrequency.weekly);
                        } else {
                          newFrequencies.remove(CollectionFrequency.weekly);
                        }
                      } else {
                        if (isWeeklySelected) return;
                        if (newValue) {
                          newFrequencies.add(frequency);
                        } else {
                          newFrequencies.remove(frequency);
                        }
                      }
                      provider.updateCollectionFrequencies(type.type, newFrequencies);
                    },
                    enabled:
                    !(isWeeklySelected && frequency != CollectionFrequency.weekly),
                  );
                }),
                CheckboxListTile(
                  title: const Text('設定しない'),
                  value: isRuleEmpty,
                  onChanged: (bool? newValue) {
                    if (newValue == true) {
                      provider.updateCollectionRule(type.type, CollectionRule.empty());
                    } else {
                      if (isRuleEmpty) {
                        provider.updateCollectionRule(type.type,
                            CollectionRule(frequencies: {CollectionFrequency.weekly}, weekdays: {Weekday.monday}));
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 曜日設定
            ExpansionTile(
              title: Text('曜日: ${provider.getWeekdayNames(currentRule.weekdays)}'),
              children: [
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
                      provider.updateCollectionWeekdays(type.type, newWeekdays);
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),

            // 収集時間設定
            ListTile(
              title: const Text('収集時間'),
              subtitle: Text(currentRule.timeOfDay ?? '未設定'),
              trailing: currentRule.timeOfDay != null
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  provider.updateCollectionTime(type.type, null);
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
                      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    );
                  },
                );
                if (pickedTime != null) {
                  final String formattedTime =
                      '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                  provider.updateCollectionTime(type.type, formattedTime);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGarbageTypeDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新しいゴミタイプを追加'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: '例: ペットボトル'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final String newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  final provider =
                  Provider.of<GarbageCollectionSettings>(context, listen: false);
                  final newType = GarbageType(
                    type: newName.toLowerCase().replaceAll(' ', '_'),
                    name: newName,
                    icon: Icons.auto_awesome,
                  );
                  provider.addGarbageType(newType);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }
}
