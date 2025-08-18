// lib/models/garbage_collection_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:garbage_app/models/garbage_type.dart';

enum CollectionFrequency { weekly, firstWeek, secondWeek, thirdWeek, fourthWeek, fifthWeek, none }
enum Weekday { none, sunday, monday, tuesday, wednesday, thursday, friday, saturday }

class CollectionRule {
  Set<CollectionFrequency> frequencies;
  Set<Weekday> weekdays;
  String? timeOfDay;

  CollectionRule({
    required this.frequencies,
    required this.weekdays,
    this.timeOfDay,
  });

  factory CollectionRule.empty() {
    return CollectionRule(
      frequencies: {},
      weekdays: {},
      timeOfDay: null,
    );
  }

  factory CollectionRule.fromJson(Map<String, dynamic> json) {
    return CollectionRule(
      frequencies: (json['frequencies'] as List).map((e) => CollectionFrequency.values.firstWhere((f) => f.toString().split('.').last == e)).toSet(),
      weekdays: (json['weekdays'] as List).map((e) => Weekday.values.firstWhere((w) => w.toString().split('.').last == e)).toSet(),
      timeOfDay: json['timeOfDay'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequencies': frequencies.map((e) => e.toString().split('.').last).toList(),
      'weekdays': weekdays.map((e) => e.toString().split('.').last).toList(),
      'timeOfDay': timeOfDay,
    };
  }

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

  bool _isNotificationEnabled = false;
  String? _notificationTime;
  int? _minutesBeforeNotification; // ★追加: 通知までの分数★

  Map<String, CollectionRule> get settings => _settings;
  List<GarbageType> get garbageTypes => _garbageTypes;

  bool get isNotificationEnabled => _isNotificationEnabled;
  String? get notificationTime => _notificationTime;
  int? get minutesBeforeNotification => _minutesBeforeNotification; // ★追加: getter★

  GarbageCollectionSettings() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final garbageTypesJsonString = prefs.getString('garbage_types');
    if (garbageTypesJsonString != null) {
      final List<dynamic> decodedList = jsonDecode(garbageTypesJsonString);
      _garbageTypes = decodedList.map((json) => GarbageType.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      _garbageTypes = [
        GarbageType(type: 'burnable', name: '燃えるごみ', icon: Icons.local_fire_department),
        GarbageType(type: 'non_burnable', name: '燃えないごみ', icon: Icons.delete_forever),
        GarbageType(type: 'recyclable', name: '資源ごみ', icon: Icons.recycling),
        GarbageType(type: 'plastic', name: 'プラスチック', icon: Icons.grass),
        GarbageType(type: 'oversized', name: '粗大ごみ', icon: Icons.work),
      ];
    }

    final settingsJsonString = prefs.getString('garbage_collection_settings');
    if (settingsJsonString != null) {
      final Map<String, dynamic> decodedData = jsonDecode(settingsJsonString);
      _settings = decodedData.map((key, value) => MapEntry(key, CollectionRule.fromJson(value)));
    } else {
      _settings = {for (var type in _garbageTypes) type.type: CollectionRule.empty()};
    }

    _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? false;
    _notificationTime = prefs.getString('notificationTime');
    _minutesBeforeNotification = prefs.getInt('minutesBeforeNotification'); // ★追加★

    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final garbageTypesJsonString = jsonEncode(_garbageTypes.map((type) => type.toJson()).toList());
    await prefs.setString('garbage_types', garbageTypesJsonString);

    final settingsJsonString = jsonEncode(_settings.map((key, value) => MapEntry(key, value.toJson())));
    await prefs.setString('garbage_collection_settings', settingsJsonString);

    await prefs.setBool('isNotificationEnabled', _isNotificationEnabled);
    await prefs.setString('notificationTime', _notificationTime ?? '');
    if (_minutesBeforeNotification != null) { // ★追加★
      await prefs.setInt('minutesBeforeNotification', _minutesBeforeNotification!);
    } else {
      await prefs.remove('minutesBeforeNotification');
    }
  }

  void setNotificationEnabled(bool value) {
    _isNotificationEnabled = value;
    saveSettings();
    notifyListeners();
  }

  void setNotificationTime(String? time) {
    _notificationTime = time;
    saveSettings();
    notifyListeners();
  }

  void setMinutesBeforeNotification(int? value) { // ★追加: setter★
    _minutesBeforeNotification = value;
    saveSettings();
    notifyListeners();
  }

  void addGarbageType(GarbageType newType) {
    if (!garbageTypes.any((type) => type.type == newType.type)) {
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
    final garbageType = _garbageTypes.firstWhere((type) => type.type == typeId, orElse: () => GarbageType(type: 'unknown', name: '不明なゴミ', icon: Icons.error));
    if (garbageType.color != null) {
      return Color(int.parse(garbageType.color!, radix: 16));
    }

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