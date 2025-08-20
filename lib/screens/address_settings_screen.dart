// lib/screens/address_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garbage_app/services/address_service.dart'; // AddressServiceをインポート

class AddressSettingsScreen extends StatefulWidget {
  const AddressSettingsScreen({super.key});

  @override
  State<AddressSettingsScreen> createState() => _AddressSettingsScreenState();
}

class _AddressSettingsScreenState extends State<AddressSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRegion;
  String? _selectedPrefecture;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    // 住所データを事前にロード
    AddressService.loadAddresses().then((_) {
      _loadAddressSettings();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 保存された住所情報を読み込む
  Future<void> _loadAddressSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrefecture = prefs.getString('prefecture');
    final savedCity = prefs.getString('city');

    setState(() {
      _selectedPrefecture = savedPrefecture;
      if (_selectedPrefecture != null) {
        // 保存された都道府県から地域を特定
        try {
          _selectedRegion = AddressService.getRegions().firstWhere((region) => AddressService.getPrefecturesForRegion(region).contains(_selectedPrefecture!));
        } catch (e) {
          _selectedRegion = null;
        }

        // 保存された市区町村が現在の都道府県リストにあるか確認
        if (AddressService.getCitiesForPrefecture(_selectedPrefecture!).contains(savedCity)) {
          _selectedCity = savedCity;
        } else {
          _selectedCity = null;
        }
      } else {
        _selectedCity = null;
      }
    });
  }

  /// 住所情報を保存する
  Future<void> _saveAddressSettings() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prefecture', _selectedPrefecture!);
      await prefs.setString('city', _selectedCity!);

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

  /// 必須フィールドの検証
  String? _validateRequired(dynamic value, String fieldName) {
    if (value == null || (value is String && value.isEmpty)) {
      return '$fieldNameを選択してください';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    List<String> prefecturesForSelectedRegion = _selectedRegion != null ? AddressService.getPrefecturesForRegion(_selectedRegion!) : [];
    List<String> citiesForSelectedPrefecture = _selectedPrefecture != null ? AddressService.getCitiesForPrefecture(_selectedPrefecture!) : [];

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
              'お住まいの住所を選択してください',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // 地域ブロックのプルダウン
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: '地域',
                    prefixIcon: Icon(Icons.public),
                    border: OutlineInputBorder(),
                  ),
                  items: AddressService.getRegions().map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRegion = newValue;
                      _selectedPrefecture = null;
                      _selectedCity = null;
                    });
                  },
                  validator: (value) => _validateRequired(value, '地域'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 都道府県のプルダウン
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedPrefecture,
                  decoration: const InputDecoration(
                    labelText: '都道府県',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  items: prefecturesForSelectedRegion.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPrefecture = newValue;
                      _selectedCity = null;
                    });
                  },
                  validator: (value) => _validateRequired(value, '都道府県'),
                  isExpanded: true,
                  hint: _selectedRegion == null ? const Text('地域を選択してください') : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 市区町村のプルダウン
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(
                    labelText: '市区町村',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  items: citiesForSelectedPrefecture.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCity = newValue;
                    });
                  },
                  validator: (value) => _validateRequired(value, '市区町村'),
                  isExpanded: true,
                  hint: _selectedPrefecture == null ? const Text('都道府県を選択してください') : null,
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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