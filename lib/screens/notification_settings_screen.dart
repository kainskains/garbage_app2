// lib/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ★追加: 通知パッケージをインポート

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  // ★追加: テスト通知を送信する非同期関数
  Future<void> _sendTestNotification(BuildContext context) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'test_channel_id',
      'Test Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // 通知ID
      'テスト通知',
      'これはテスト通知です。',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<GarbageCollectionSettings>(context);
    final List<int> minutesOptions = [1, 5, 10, 15, 30, 60, 120];

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '通知を有効にする',
                  style: TextStyle(fontSize: 18),
                ),
                Switch(
                  value: settingsProvider.isNotificationEnabled,
                  onChanged: (bool newValue) {
                    settingsProvider.setNotificationEnabled(newValue);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('通知時間'),
              subtitle: Text(
                settingsProvider.notificationTime ?? '未設定',
                style: TextStyle(
                  color: settingsProvider.isNotificationEnabled ? null : Colors.grey,
                ),
              ),
              trailing: settingsProvider.notificationTime != null
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: settingsProvider.isNotificationEnabled
                    ? () {
                  settingsProvider.setNotificationTime(null);
                }
                    : null,
              )
                  : null,
              onTap: settingsProvider.isNotificationEnabled
                  ? () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: settingsProvider.notificationTime != null
                      ? TimeOfDay(
                    hour: int.parse(settingsProvider.notificationTime!.split(':')[0]),
                    minute: int.parse(settingsProvider.notificationTime!.split(':')[1]),
                  )
                      : TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  final String formattedTime =
                      '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                  settingsProvider.setNotificationTime(formattedTime);
                }
              }
                  : null,
            ),

            ListTile(
              title: const Text('何分前に通知'),
              subtitle: Text(
                settingsProvider.minutesBeforeNotification != null
                    ? '${settingsProvider.minutesBeforeNotification}分前'
                    : '未設定',
                style: TextStyle(
                  color: settingsProvider.isNotificationEnabled ? null : Colors.grey,
                ),
              ),
              trailing: settingsProvider.isNotificationEnabled
                  ? DropdownButton<int>(
                value: settingsProvider.minutesBeforeNotification,
                hint: const Text('選択'),
                onChanged: (int? newValue) {
                  settingsProvider.setMinutesBeforeNotification(newValue);
                },
                items: minutesOptions.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value分前'),
                  );
                }).toList(),
              )
                  : null,
            ),

            const SizedBox(height: 40),

            // ★追加: 通知テスト用のボタン
            ElevatedButton(
              onPressed: () {
                _sendTestNotification(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('テスト通知が送信されました。'),
                  ),
                );
              },
              child: const Text('通知を今すぐテスト'),
            ),
          ],
        ),
      ),
    );
  }
}