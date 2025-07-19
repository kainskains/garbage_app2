// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer を使うので、ここではProvider.ofは直接使わず、builderで受け取る
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
            return _buildGarbageTypeSetting(context, type); // settingsProvider は Consumer から受け取る
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGarbageTypeSetting(BuildContext context, GarbageType type) {
    // Consumer を使って、このウィジェットだけがリビルドされるように最適化
    return Consumer<GarbageCollectionSettings>(
      builder: (context, provider, child) { // provider が GarbageCollectionSettings のインスタンス
        final CollectionRule currentRule = provider.settings[type] ?? CollectionRule.empty();

        // 「毎週」が現在選択されているかどうかのフラグ
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
                  title: Text('頻度: ${currentRule.frequencies.isEmpty ? '未設定' : currentRule.frequencies.map((f) => provider.getFrequencyName(f)).join(', ')}'),
                  children: [
                    // 全ての頻度オプション
                    // CollectionFrequency.values のうち CollectionFrequency.none を除外して表示
                    ...CollectionFrequency.values.map((frequency) {
                      return CheckboxListTile(
                        title: Text(provider.getFrequencyName(frequency)),
                        value: currentRule.frequencies.contains(frequency),
                        onChanged: (bool? newValue) {
                          if (newValue == null) return; // null の場合は何もしない

                          final Set<CollectionFrequency> newFrequencies = Set.from(currentRule.frequencies);

                          if (frequency == CollectionFrequency.weekly) {
                            // 「毎週」のチェックボックスが操作された場合
                            if (newValue) {
                              // 「毎週」をオンにする場合、他の全ての週をクリアし、「毎週」だけを追加
                              newFrequencies.clear();
                              newFrequencies.add(CollectionFrequency.weekly);
                            } else {
                              // 「毎週」をオフにする場合、クリア（何も残さない）
                              newFrequencies.remove(CollectionFrequency.weekly);
                              // 「毎週」をオフにした場合、自動的に第1週目月曜日に設定されるのは不自然なため、
                              // 基本的には何もしない。ユーザーが改めて第X週目や曜日を設定するのを待つ。
                              // 必要であれば、ここで「曜日」も「未設定」にするロジックを追加しても良い。
                              // 例: provider.updateCollectionWeekday(type, Weekday.none);
                            }
                          } else {
                            // 「第X週目」のチェックボックスが操作された場合
                            if (isWeeklySelected) {
                              // 「毎週」が選択中の場合は、何もしない（非活性にしているので、実質ここには来ないはずだが念のため）
                              return;
                            }
                            if (newValue) {
                              // 「第X週目」をオンにする場合
                              newFrequencies.add(frequency);
                            } else {
                              // 「第X週目」をオフにする場合
                              newFrequencies.remove(frequency);
                            }
                          }
                          provider.updateCollectionFrequencies(type, newFrequencies);
                        },
                        // 「毎週」が選択されている場合、かつ現在のチェックボックスが「毎週」ではない場合は非活性にする
                        enabled: !(isWeeklySelected && frequency != CollectionFrequency.weekly),
                      );
                    }).toList(),
                    // 「設定しない」チェックボックス
                    CheckboxListTile(
                      title: const Text('設定しない'),
                      value: currentRule.frequencies.isEmpty && currentRule.weekday == Weekday.none,
                      onChanged: (bool? newValue) {
                        if (newValue == true) {
                          // 未設定を選択した場合、全ての頻度と曜日をnoneにする
                          provider.updateCollectionRule(type, CollectionRule.empty());
                        } else {
                          // 未設定解除の場合は、最低限のルールを初期化 (例: 毎週月曜)
                          // ただし、頻度が空で曜日が設定済みの場合など、既存の値を考慮する
                          if (currentRule.frequencies.isEmpty && currentRule.weekday == Weekday.none) {
                            provider.updateCollectionRule(type, CollectionRule(frequencies: {CollectionFrequency.weekly}, weekday: Weekday.monday));
                          }
                          // 頻度があるが曜日がnoneの場合は、曜日を月曜に設定する
                          else if (currentRule.frequencies.isNotEmpty && currentRule.weekday == Weekday.none) {
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
                            // 頻度も曜日も未設定の状態から曜日を設定した場合、デフォルトで「毎週」にする
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