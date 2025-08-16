// lib/screens/address_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressSettingsScreen extends StatefulWidget {
  const AddressSettingsScreen({super.key});

  @override
  State<AddressSettingsScreen> createState() => _AddressSettingsScreenState();
}

class _AddressSettingsScreenState extends State<AddressSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prefectureController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddressSettings();
  }

  @override
  void dispose() {
    _prefectureController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // 保存された住所情報を読み込む
  Future<void> _loadAddressSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefectureController.text = prefs.getString('prefecture') ?? '';
      _cityController.text = prefs.getString('city') ?? '';
    });
  }

  // 住所情報を保存する
  Future<void> _saveAddressSettings() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prefecture', _prefectureController.text);
      await prefs.setString('city', _cityController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('住所が保存されました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // 必須フィールドの検証
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldNameを入力してください';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('住所設定'),
        actions: [
          TextButton(
            onPressed: _saveAddressSettings,
            child: const Text(
              '保存',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'お住まいの住所を入力してください',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // 都道府県
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: _prefectureController,
                  decoration: const InputDecoration(
                    labelText: '都道府県',
                    hintText: '東京都',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateRequired(value, '都道府県'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 市区町村
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: '市区町村',
                    hintText: '渋谷区',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateRequired(value, '市区町村'),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 保存ボタン
            ElevatedButton(
              onPressed: _saveAddressSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '住所を保存',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // 注意事項
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'ご注意',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 住所情報は、ごみ収集エリアの特定に使用されます\n'
                        '• 入力された情報は端末内にのみ保存され、外部に送信されません\n'
                        '• 正確な住所を入力することで、より適切なごみ収集情報を提供できます',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}