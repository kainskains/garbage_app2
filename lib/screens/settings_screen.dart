// lib/screens/settings_screen.dart (修正後)
import 'package:flutter/material.dart';
import 'package:garbage_app/screens/date_settings_screen.dart'; // 新しい日付設定画面
import 'package:garbage_app/screens/time_settings_screen.dart'; // 新しい時間設定画面

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
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: const Text(
                'ごみ収集日設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DateSettingsScreen()),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: const Text(
                'ごみ収集時間設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TimeSettingsScreen()),
                );
              },
            ),
          ),
          // 今後追加されるであろう、その他の設定項目
        ],
      ),
    );
  }
}