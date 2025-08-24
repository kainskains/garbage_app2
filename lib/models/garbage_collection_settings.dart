import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:garbage_app/models/garbage_type.dart';

enum CollectionFrequency { weekly, firstWeek, secondWeek, thirdWeek, fourthWeek, fifthWeek }
enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday, none }

class CollectionRule {
  Set<CollectionFrequency> frequencies;
  Set<Weekday> weekdays;
  String? timeOfDay; // "HH:MM"

  CollectionRule({required this.frequencies, required this.weekdays, this.timeOfDay});

  factory CollectionRule.empty() {
    return CollectionRule(frequencies: {}, weekdays: {}, timeOfDay: null);
  }

  factory CollectionRule.fromJson(Map<String, dynamic> json) {
    return CollectionRule(
      frequencies: (json['frequencies'] as List<dynamic>?)
          ?.map((e) => CollectionFrequency.values.firstWhere((v) => v.toString().split('.').last == e))
          .toSet() ??
          {},
      weekdays: (json['weekdays'] as List<dynamic>?)
          ?.map((e) => Weekday.values.firstWhere((v) => v.toString().split('.').last == e))
          .toSet() ??
          {},
      timeOfDay: json['timeOfDay'],
    );
  }

  Map<String, dynamic> toJson() => {
    'frequencies': frequencies.map((e) => e.toString().split('.').last).toList(),
    'weekdays': weekdays.map((e) => e.toString().split('.').last).toList(),
    'timeOfDay': timeOfDay,
  };

  CollectionRule copyWith({Set<CollectionFrequency>? frequencies, Set<Weekday>? weekdays, String? timeOfDay}) {
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
  int? _minutesBeforeNotification;

  Map<String, CollectionRule> get settings => _settings;
  List<GarbageType> get garbageTypes => _garbageTypes;
  bool get isNotificationEnabled => _isNotificationEnabled;
  String? get notificationTime => _notificationTime;
  int? get minutesBeforeNotification => _minutesBeforeNotification;

  GarbageCollectionSettings() {
    loadSettings();
  }

  // -------------------- Load & Save --------------------
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Garbage Types
    final garbageTypesJsonString = prefs.getString('garbage_types');
    if (garbageTypesJsonString != null) {
      final List<dynamic> decodedList = jsonDecode(garbageTypesJsonString);
      _garbageTypes = decodedList.map((json) => GarbageType.fromJson(json)).toList();
    } else {
      _garbageTypes = _initialGarbageTypes();
    }

    // Collection Settings
    final settingsJsonString = prefs.getString('garbage_collection_settings');
    if (settingsJsonString != null) {
      final Map<String, dynamic> decodedData = jsonDecode(settingsJsonString);
      _settings = decodedData.map((key, value) => MapEntry(key, CollectionRule.fromJson(value)));
    } else {
      _settings = {for (var type in _garbageTypes) type.type: CollectionRule.empty()};
    }

    _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? false;
    _notificationTime = prefs.getString('notificationTime');
    _minutesBeforeNotification = prefs.getInt('minutesBeforeNotification');

    bool needsSave = false;
    for (var type in _garbageTypes) {
      final rule = _settings[type.type];
      if (rule == null || rule.frequencies.isEmpty || rule.weekdays.isEmpty || rule.timeOfDay == null) {
        _settings[type.type] = CollectionRule(
          frequencies: {CollectionFrequency.weekly},
          weekdays: {Weekday.monday},
          timeOfDay: '08:00',
        );
        needsSave = true;
      }
    }

    if (needsSave) await saveSettings();
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('garbage_types', jsonEncode(_garbageTypes.map((t) => t.toJson()).toList()));
    await prefs.setString(
        'garbage_collection_settings', jsonEncode(_settings.map((k, v) => MapEntry(k, v.toJson()))));
    await prefs.setBool('isNotificationEnabled', _isNotificationEnabled);
    await prefs.setString('notificationTime', _notificationTime ?? '');
    if (_minutesBeforeNotification != null) {
      await prefs.setInt('minutesBeforeNotification', _minutesBeforeNotification!);
    } else {
      await prefs.remove('minutesBeforeNotification');
    }
  }

  // -------------------- Initial Garbage Types --------------------
  List<GarbageType> _initialGarbageTypes() {
    return [
      GarbageType(type: 'burnable', name: '燃えるごみ', icon: Icons.local_fire_department, color: 'FFCDD2'),
      GarbageType(type: 'non_burnable', name: '燃えないごみ', icon: Icons.delete_forever, color: 'BBDEFB'),
      GarbageType(type: 'recyclable', name: '資源ごみ', icon: Icons.recycling, color: 'C8E6C9'),
      GarbageType(type: 'plastic', name: 'プラスチック', icon: Icons.grass, color: 'FFF9C4'),
      GarbageType(type: 'oversized', name: '粗大ごみ', icon: Icons.work, color: 'E1BEE7'),
    ];
  }

  // -------------------- Reset to Initial --------------------
  void resetGarbageTypes() {
    _garbageTypes = _initialGarbageTypes();
    _settings = {for (var type in _garbageTypes) type.type: CollectionRule.empty()};
    saveSettings();
    notifyListeners();
  }

  // -------------------- Getter Helpers --------------------
  Color getGarbageTypeColor(String typeId) {
    final type = _garbageTypes.firstWhere(
          (t) => t.type == typeId,
      orElse: () => GarbageType(type: 'unknown', name: '不明', icon: Icons.error, color: '000000'),
    );
    try {
      return Color(int.parse('0xFF${type.color}'));
    } catch (e) {
      print('Error parsing color for typeId: $typeId, color string: ${type.color}');
      return Colors.black; // Return a default color if parsing fails
    }
  }

  String getGarbageTypeName(String typeId) {
    final type = _garbageTypes.firstWhere(
          (t) => t.type == typeId,
      orElse: () => GarbageType(type: 'unknown', name: '不明', icon: Icons.error, color: '000000'),
    );
    return type.name;
  }

  String getWeekdayName(Weekday weekday) {
    switch (weekday) {
      case Weekday.monday:
        return '月';
      case Weekday.tuesday:
        return '火';
      case Weekday.wednesday:
        return '水';
      case Weekday.thursday:
        return '木';
      case Weekday.friday:
        return '金';
      case Weekday.saturday:
        return '土';
      case Weekday.sunday:
        return '日';
      default:
        return '';
    }
  }

  String getWeekdayNames(Set<Weekday> weekdays) {
    return weekdays.map(getWeekdayName).join(', ');
  }

  String getFrequencyName(CollectionFrequency freq) {
    switch (freq) {
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
        return '';
    }
  }

  // -------------------- Update Methods --------------------
  void addGarbageType(GarbageType newType) {
    if (!_garbageTypes.any((t) => t.type == newType.type)) {
      _garbageTypes.add(newType);
      _settings[newType.type] = CollectionRule.empty();
      saveSettings();
      notifyListeners();
    }
  }

  void removeGarbageType(String typeId) {
    _garbageTypes.removeWhere((t) => t.type == typeId);
    _settings.remove(typeId);
    saveSettings();
    notifyListeners();
  }

  void updateCollectionRule(String typeId, CollectionRule newRule) {
    _settings[typeId] = newRule;
    saveSettings();
    notifyListeners();
  }

  void updateCollectionFrequencies(String typeId, Set<CollectionFrequency> newFrequencies) {
    final rule = _settings[typeId];
    if (rule != null) {
      _settings[typeId] = rule.copyWith(frequencies: newFrequencies);
      saveSettings();
      notifyListeners();
    }
  }

  void updateCollectionWeekdays(String typeId, Set<Weekday> newWeekdays) {
    final rule = _settings[typeId];
    if (rule != null) {
      _settings[typeId] = rule.copyWith(weekdays: newWeekdays);
      saveSettings();
      notifyListeners();
    }
  }

  void updateCollectionTime(String typeId, String? newTime) {
    final rule = _settings[typeId];
    if (rule != null) {
      _settings[typeId] = rule.copyWith(timeOfDay: newTime);
      saveSettings();
      notifyListeners();
    }
  }

  void setNotificationEnabled(bool value) {
    _isNotificationEnabled = value;
    saveSettings();
    notifyListeners();
  }

  void setMinutesBeforeNotification(int? minutes) {
    _minutesBeforeNotification = minutes;
    saveSettings();
    notifyListeners();
  }

  // -------------------- TZDateTime Conversion --------------------
  tz.TZDateTime? calculateNextCollectionDateTime(String typeId) {
    final rule = _settings[typeId];
    if (rule == null || rule.timeOfDay == null || rule.weekdays.isEmpty || rule.frequencies.isEmpty) return null;

    final int hour = int.parse(rule.timeOfDay!.split(':')[0]);
    final int minute = int.parse(rule.timeOfDay!.split(':')[1]);
    final now = tz.TZDateTime.now(tz.local);

    Weekday getWeekdayEnumFromDart(int dartWeekday) {
      switch (dartWeekday) {
        case DateTime.monday:
          return Weekday.monday;
        case DateTime.tuesday:
          return Weekday.tuesday;
        case DateTime.wednesday:
          return Weekday.wednesday;
        case DateTime.thursday:
          return Weekday.thursday;
        case DateTime.friday:
          return Weekday.friday;
        case DateTime.saturday:
          return Weekday.saturday;
        case DateTime.sunday:
          return Weekday.sunday;
        default:
          return Weekday.none;
      }
    }

    tz.TZDateTime? found;
    for (int i = 0; i < 35; i++) {
      final checkDate = now.add(Duration(days: i));
      final currentWeekday = getWeekdayEnumFromDart(checkDate.weekday);

      if (rule.weekdays.contains(currentWeekday)) {
        bool isFrequencyMatch = false;
        if (rule.frequencies.contains(CollectionFrequency.weekly)) {
          isFrequencyMatch = true;
        } else {
          final weekOfMonth = ((checkDate.day - 1) ~/ 7) + 1;
          if ((weekOfMonth == 1 && rule.frequencies.contains(CollectionFrequency.firstWeek)) ||
              (weekOfMonth == 2 && rule.frequencies.contains(CollectionFrequency.secondWeek)) ||
              (weekOfMonth == 3 && rule.frequencies.contains(CollectionFrequency.thirdWeek)) ||
              (weekOfMonth == 4 && rule.frequencies.contains(CollectionFrequency.fourthWeek)) ||
              (weekOfMonth == 5 && rule.frequencies.contains(CollectionFrequency.fifthWeek))) {
            isFrequencyMatch = true;
          }
        }

        if (isFrequencyMatch) {
          final candidateDateTime =
          tz.TZDateTime(tz.local, checkDate.year, checkDate.month, checkDate.day, hour, minute);
          if (candidateDateTime.isAfter(now)) {
            found = candidateDateTime;
            break;
          }
        }
      }
    }
    return found;
  }
}