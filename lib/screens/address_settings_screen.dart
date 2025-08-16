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
  String? _selectedRegion;
  String? _selectedPrefecture;
  String? _selectedCity;

  // 地域ブロックの定義
  static const List<String> _regions = [
    '北海道',
    '東北',
    '関東',
    '中部',
    '近畿',
    '中国',
    '四国',
    '九州・沖縄',
  ];

  // 地域ブロックごとの都道府県リスト
  static const Map<String, List<String>> _regionPrefectures = {
    '北海道': ['北海道'],
    '東北': ['青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県'],
    '関東': ['茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県'],
    '中部': ['新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県', '静岡県', '愛知県'],
    '近畿': ['三重県', '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県'],
    '中国': ['鳥取県', '島根県', '岡山県', '広島県', '山口県'],
    '四国': ['徳島県', '香川県', '愛媛県', '高知県'],
    '九州・沖縄': ['福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'],
  };

  // 都道府県ごとの市区町村リスト（デモ用）
  static const Map<String, List<String>> _cities = {
    '東京都': ['新宿区', '渋谷区', '世田谷区', '港区', '杉並区'], // 杉並区を追加
    '神奈川県': ['横浜市', '川崎市', '相模原市', '藤沢市'],
    '大阪府': ['大阪市', '堺市', '東大阪市', '豊中市'],
    '愛知県': ['名古屋市', '豊田市', '一宮市', '岡崎市'],
    '北海道': ['札幌市', '函館市', '旭川市', '釧路市'],
    '福岡県': ['福岡市', '北九州市', '久留米市', '大牟田市'],
    '宮城県': ['仙台市', '石巻市', '大崎市', '登米市'],
  };

  @override
  void initState() {
    super.initState();
    _loadAddressSettings();
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
        _selectedRegion = _regionPrefectures.entries
            .firstWhere((entry) => entry.value.contains(_selectedPrefecture!))
            .key;

        // 保存された市区町村が現在の都道府県リストにあるか確認し、なければnullにする
        // これがエラーを修正する重要なロジックです
        if (_cities[_selectedPrefecture]?.contains(savedCity) == true) {
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
    List<String> prefecturesForSelectedRegion = _regionPrefectures[_selectedRegion] ?? [];
    List<String> citiesForSelectedPrefecture = _cities[_selectedPrefecture] ?? [];

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
                  items: _regions.map((String value) {
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