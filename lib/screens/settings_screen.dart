// lib/screens/settings_screen.dart (住所設定追加版)
import 'package:flutter/material.dart';
import 'package:garbage_app/screens/date_settings_screen.dart'; // 日付設定画面
import 'package:garbage_app/screens/time_settings_screen.dart'; // 時間設定画面
import 'package:garbage_app/screens/address_settings_screen.dart'; // 住所設定画面

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
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

          // ごみ収集日設定
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: Colors.blue,
                size: 28,
              ),
              title: const Text(
                'ごみ収集日設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'ごみの収集日を設定',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DateSettingsScreen()),
                );
              },
            ),
          ),

          // ごみ収集時間設定
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(
                Icons.access_time,
                color: Colors.green,
                size: 28,
              ),
              title: const Text(
                'ごみ収集時間設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'ごみの収集時間を設定',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TimeSettingsScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // セクション分けのための区切り線とタイトル
          const Divider(thickness: 1),
          const SizedBox(height: 16),

          const Text(
            'その他の設定',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 16),

          // 今後追加される可能性のある設定項目のプレースホルダー
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
                // 今後実装予定
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('この機能は今後実装予定です'),
                  ),
                );
              },
            ),
          ),

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
                // アプリ情報表示
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