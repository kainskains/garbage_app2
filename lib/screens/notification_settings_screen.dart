// lib/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';
import 'package:garbage_app/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final List<int> _notificationMinutes = [5, 10, 15, 30, 60, 120];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
      ),
      body: Consumer<GarbageCollectionSettings>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 通知の有効/無効切り替え
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '通知の設定',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text('通知を有効にする'),
                        subtitle: const Text('ゴミ収集日の前に通知を送信します'),
                        value: provider.isNotificationEnabled,
                        onChanged: (bool value) async {
                          provider.setNotificationEnabled(value);

                          if (value) {
                            // 通知許可をリクエスト
                            final notificationService = NotificationService();
                            await notificationService.requestPermissions();
                            // 通知をスケジュール
                            await notificationService.scheduleAllNotifications();
                          } else {
                            // 全ての通知をキャンセル
                            final notificationService = NotificationService();
                            await notificationService.cancelAllNotifications();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (provider.isNotificationEnabled) ...[
                const SizedBox(height: 16),

                // 通知タイミング設定
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '通知タイミング',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'ゴミ収集時間の何分前に通知しますか？',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        ..._notificationMinutes.map((minutes) {
                          return RadioListTile<int>(
                            title: Text('$minutes分前'),
                            value: minutes,
                            groupValue: provider.minutesBeforeNotification,
                            onChanged: (int? value) async {
                              if (value != null) {
                                provider.setMinutesBeforeNotification(value);
                                // 通知を再スケジュール
                                final notificationService = NotificationService();
                                await notificationService.scheduleAllNotifications();
                              }
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 次回の通知予定表示
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '次回の通知予定',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ...provider.garbageTypes.map((type) {
                          final nextCollection = provider.calculateNextCollectionDateTime(type.type);
                          if (nextCollection == null) {
                            return ListTile(
                              leading: Icon(type.icon, color: provider.getGarbageTypeColor(type.type)),
                              title: Text(type.name),
                              subtitle: const Text('収集日が設定されていません'),
                            );
                          }

                          final notificationTime = provider.minutesBeforeNotification != null
                              ? nextCollection.subtract(Duration(minutes: provider.minutesBeforeNotification!))
                              : null;

                          return ListTile(
                            leading: Icon(type.icon, color: provider.getGarbageTypeColor(type.type)),
                            title: Text(type.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('収集日: ${_formatDateTime(nextCollection)}'),
                                if (notificationTime != null)
                                  Text('通知: ${_formatDateTime(notificationTime)}'),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // テスト通知ボタン
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'テスト',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final notificationService = NotificationService();
                              await notificationService.showTestNotification();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('テスト通知を送信しました')),
                                );
                              }
                            },
                            child: const Text('テスト通知を送信'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}