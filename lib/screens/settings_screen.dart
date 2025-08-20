// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:garbage_app/screens/address_settings_screen.dart';
import 'package:garbage_app/screens/reminder_settings_screen.dart';
import 'package:garbage_app/screens/notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 住所設定
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 28,
              ),
              title: const Text(
                '住所設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'お住まいの住所を設定',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddressSettingsScreen()),
                );
              },
            ),
          ),

          // ごみ収集リマインダー設定
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(
                Icons.schedule,
                color: Colors.green,
                size: 28,
              ),
              title: const Text(
                'ごみ収集リマインダー設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'ごみ収集日と時間をまとめて設定',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ReminderSettingsScreen()),
                );
              },
            ),
          ),

          // 通知設定
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(
                Icons.notifications,
                color: Colors.orange,
                size: 28,
              ),
              title: const Text(
                '通知設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'リマインダー通知の設定',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                );
              },
            ),
          ),

          // アプリについて
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(
                Icons.info_outline,
                color: Colors.purple,
                size: 28,
              ),
              title: const Text(
                'アプリについて',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'バージョン情報とライセンス',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'ごみ収集アプリ',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 Your Company',
                  children: const [
                    Text('このアプリは地域のごみ収集情報を管理するためのアプリです。'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}