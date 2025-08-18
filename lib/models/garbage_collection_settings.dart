// lib/models/garbage_collection_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:garbage_app/models/garbage_type.dart';

// 既存の列挙型とヘルパークラス
enum CollectionFrequency { weekly, firstWeek, secondWeek, thirdWeek, fourthWeek, fifthWeek, none }
enum Weekday { none, sunday, monday, tuesday, wednesday, thursday, friday, saturday }

/// ごみ収集のルールを定義するクラス
class CollectionRule {
  Set<CollectionFrequency> frequencies;
  Set<Weekday> weekdays;
  String? timeOfDay;

  CollectionRule({
    required this.frequencies,
    required this.weekdays,
    this.timeOfDay,
  });

  // 空のルールを返すファクトリコンストラクタ
  factory CollectionRule.empty() {
    return CollectionRule(
      frequencies: {},
      weekdays: {},
      timeOfDay: null,
    );
  }

  // JSONからCollectionRuleオブジェクトを作成
  factory CollectionRule.fromJson(Map<String, dynamic> json) {
    return CollectionRule(
      frequencies: (json['frequencies'] as List).map((e) => CollectionFrequency.values.firstWhere((f) => f.toString() == 'CollectionFrequency.$e')).toSet(),
      weekdays: (json['weekdays'] as List).map((e) => Weekday.values.firstWhere((w) => w.toString() == 'Weekday.$e')).toSet(),
      timeOfDay: json['timeOfDay'] as String?,
    );
  }

  // CollectionRuleオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'frequencies': frequencies.map((e) => e.toString().split('.').last).toList(),
      'weekdays': weekdays.map((e) => e.toString().split('.').last).toList(),
      'timeOfDay': timeOfDay,
    };
  }

  // copyWithヘルパーメソッドをCollectionRuleクラス内に追加
  CollectionRule copyWith({
    Set<CollectionFrequency>? frequencies,
    Set<Weekday>? weekdays,
    String? timeOfDay,
  }) {
    return CollectionRule(
      frequencies: frequencies ?? this.frequencies,
      weekdays: weekdays ?? this.weekdays,
      timeOfDay: timeOfDay ?? this.timeOfDay,
    );
  }
}

class GarbageCollectionSettings with ChangeNotifier {
  Map<String, CollectionRule> _settings = {};
  List<GarbageType> _garbageTypes = [];

  Map<String, CollectionRule> get settings => _settings;
  List<GarbageType> get garbageTypes => _garbageTypes;

  GarbageCollectionSettings() {
    loadGarbageTypes();
    loadSettings();
  }

  Future<void> loadGarbageTypes() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/garbage_types.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _garbageTypes = jsonList.map((json) => GarbageType.fromJson(json as Map<String, dynamic>)).toList();
      notifyListeners();
      print('ゴミタイプデータを読み込みました');
    } catch (e) {
      print('ゴミタイプデータの読み込みに失敗しました: $e');
    }
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJsonString = prefs.getString('garbage_collection_settings');
    if (settingsJsonString != null) {
      final Map<String, dynamic> decodedData = jsonDecode(settingsJsonString);
      _settings = decodedData.map((key, value) => MapEntry(key, CollectionRule.fromJson(value)));
      notifyListeners();
    }
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJsonString = jsonEncode(_settings.map((key, value) => MapEntry(key, value.toJson())));
    await prefs.setString('garbage_collection_settings', settingsJsonString);
  }

  void addGarbageType(GarbageType newType) {
    if (!_garbageTypes.any((type) => type.type == newType.type)) {
      _garbageTypes.add(newType);
      _settings[newType.type] = CollectionRule.empty();
      saveSettings();
      notifyListeners();
    }
  }

  void removeGarbageType(String typeId) {
    _garbageTypes.removeWhere((type) => type.type == typeId);
    _settings.remove(typeId);
    saveSettings();
    notifyListeners();
  }

  String getGarbageTypeName(String typeId) {
    return _garbageTypes.firstWhere((type) => type.type == typeId, orElse: () => GarbageType(type: 'unknown', name: '不明なゴミ', icon: Icons.error)).name;
  }

  String getFrequencyName(CollectionFrequency frequency) {
    switch (frequency) {
      case CollectionFrequency.weekly:
        return '毎週';
      case CollectionFrequency.firstWeek:
        return '第1週';
      case CollectionFrequency.secondWeek:
        return '第2週';
      case CollectionFrequency.thirdWeek:
        return '第3週';
      case CollectionFrequency.fourthWeek:
        return '第4週';
      case CollectionFrequency.fifthWeek:
        return '第5週';
      default:
        return 'なし';
    }
  }

  String getWeekdayName(Weekday weekday) {
    switch (weekday) {
      case Weekday.sunday:
        return '日曜日';
      case Weekday.monday:
        return '月曜日';
      case Weekday.tuesday:
        return '火曜日';
      case Weekday.wednesday:
        return '水曜日';
      case Weekday.thursday:
        return '木曜日';
      case Weekday.friday:
        return '金曜日';
      case Weekday.saturday:
        return '土曜日';
      default:
        return '未設定';
    }
  }

  String getWeekdayNames(Set<Weekday> weekdays) {
    if (weekdays.isEmpty) return '未設定';
    final sortedWeekdays = weekdays.toList()..sort((a, b) => a.index.compareTo(b.index));
    return sortedWeekdays.map((e) => getWeekdayName(e).substring(0, 1)).join(', ');
  }

  Color getGarbageTypeColor(String typeId) {
    final colors = {
      'burnable': Colors.red,
      'non_burnable': Colors.blue,
      'recyclable': Colors.green,
      'plastic': Colors.orange,
      'oversized': Colors.purple,
    };
    return colors[typeId] ?? Colors.grey;
  }

  void updateCollectionRule(String typeId, CollectionRule newRule) {
    _settings[typeId] = newRule;
    saveSettings();
    notifyListeners();
  }

  void updateCollectionFrequencies(String typeId, Set<CollectionFrequency> frequencies) {
    _settings[typeId] = _settings[typeId]!.copyWith(frequencies: frequencies);
    saveSettings();
    notifyListeners();
  }

  void updateCollectionWeekdays(String typeId, Set<Weekday> weekdays) {
    _settings[typeId] = _settings[typeId]!.copyWith(weekdays: weekdays);
    saveSettings();
    notifyListeners();
  }

  void updateCollectionTime(String typeId, String? time) {
    _settings[typeId] = _settings[typeId]!.copyWith(timeOfDay: time);
    saveSettings();
    notifyListeners();
  }
}