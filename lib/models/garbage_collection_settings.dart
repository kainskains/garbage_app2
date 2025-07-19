// lib/models/garbage_collection_settings.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // null-safe な collection を使用する場合

// ゴミのタイプを定義するEnum
enum GarbageType {
  burnable,   // 燃えるごみ
  nonBurnable,// 燃えないごみ
  plastic,    // プラスチック
  paper,      // 紙
  cardboard,  // 段ボール
  bottlesCans,// びん・かん
  petBottles, // ペットボトル
  hazardous,  // 危険ごみ
  recyclable, // 資源ごみ（その他）
}

// 収集曜日を定義するEnum
enum Weekday {
  none,       // 設定しない
  monday,     // 月曜日
  tuesday,    // 火曜日
  wednesday,  // 水曜日
  thursday,   // 木曜日
  friday,     // 金曜日
  saturday,   // 土曜日
  sunday,     // 日曜日
}

// 収集頻度を定義するEnum
enum CollectionFrequency {
  weekly,       // 毎週
  firstWeek,    // 第1週目
  secondWeek,   // 第2週目
  thirdWeek,    // 第3週目
  fourthWeek,   // 第4週目
  fifthWeek,    // 第5週目
}

// ごみ収集ルールを定義するクラス
class CollectionRule {
  final Set<CollectionFrequency> frequencies;
  final Set<Weekday> weekdays;
  final String? timeOfDay; // ★追加済み: 収集時間 (HH:MM形式) ★

  CollectionRule({
    this.frequencies = const {},
    this.weekdays = const {},
    this.timeOfDay, // ★追加済み: コンストラクタ引数 ★
  });

  // 空のルールを返すファクトリコンストラクタ
  factory CollectionRule.empty() {
    return CollectionRule(frequencies: {}, weekdays: {}, timeOfDay: null); // ★変更済み: timeOfDay を null に ★
  }

  // Firestoreに保存するためのマップに変換 (SharedPreferencesで使用)
  Map<String, dynamic> toFirestore() {
    return {
      'frequencies': frequencies.map((f) => f.index).toList(),
      'weekdays': weekdays.map((d) => d.index).toList(),
      'timeOfDay': timeOfDay, // ★追加済み: timeOfDay をマップに含める ★
    };
  }

  // Firestoreから読み込むためのファクトリコンストラクタ (SharedPreferencesで使用)
  factory CollectionRule.fromFirestore(Map<String, dynamic> data) {
    final List<dynamic>? freqIndices = data['frequencies'];
    final List<dynamic>? weekdayIndices = data['weekdays'];
    final String? time = data['timeOfDay']; // ★追加済み: timeOfDay を読み込む ★

    return CollectionRule(
      frequencies: freqIndices != null
          ? freqIndices.map((e) => CollectionFrequency.values[e as int]).toSet()
          : {},
      weekdays: weekdayIndices != null
          ? weekdayIndices.map((e) => Weekday.values[e as int]).toSet()
          : {},
      timeOfDay: time, // ★追加済み: timeOfDay を設定 ★
    );
  }
}

// ごみ収集設定全体を管理するプロバイダークラス
class GarbageCollectionSettings with ChangeNotifier {
  Map<GarbageType, CollectionRule> _settings = {};

  // コンストラクタで設定を非同期でロード
  GarbageCollectionSettings() {
    _loadSettings();
  }

  Map<GarbageType, CollectionRule> get settings => _settings;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsString = prefs.getString('garbage_collection_settings');

    if (settingsString != null) {
      final Map<String, dynamic> decodedData = json.decode(settingsString);
      _settings = decodedData.map((key, value) {
        final GarbageType type = GarbageType.values.firstWhere(
              (e) => e.toString().split('.').last == key,
          orElse: () => GarbageType.burnable, // Fallback (should not happen if saved correctly)
        );
        return MapEntry(type, CollectionRule.fromFirestore(value as Map<String, dynamic>));
      });
    } else {
      // 初期設定: 全てのゴミタイプに対して空のルールを設定
      for (var type in GarbageType.values) {
        _settings[type] = CollectionRule.empty();
      }
    }
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> encodedData = _settings.map((key, value) {
      return MapEntry(key.toString().split('.').last, value.toFirestore());
    });
    await prefs.setString('garbage_collection_settings', json.encode(encodedData));
  }

  void updateCollectionRule(GarbageType type, CollectionRule newRule) {
    _settings[type] = newRule;
    saveSettings();
    notifyListeners();
  }

  void updateCollectionFrequencies(GarbageType type, Set<CollectionFrequency> newFrequencies) {
    final currentRule = _settings[type] ?? CollectionRule.empty();
    updateCollectionRule(type, CollectionRule(frequencies: newFrequencies, weekdays: currentRule.weekdays, timeOfDay: currentRule.timeOfDay)); // ★変更済み: timeOfDay を保持 ★
  }

  void updateCollectionWeekdays(GarbageType type, Set<Weekday> newWeekdays) {
    final currentRule = _settings[type] ?? CollectionRule.empty();
    updateCollectionRule(type, CollectionRule(frequencies: currentRule.frequencies, weekdays: newWeekdays, timeOfDay: currentRule.timeOfDay)); // ★変更済み: timeOfDay を保持 ★
  }

  // ★追加済み: 収集時間を更新するメソッド ★
  void updateCollectionTime(GarbageType type, String? newTime) {
    final currentRule = _settings[type] ?? CollectionRule.empty();
    updateCollectionRule(type, CollectionRule(frequencies: currentRule.frequencies, weekdays: currentRule.weekdays, timeOfDay: newTime));
  }

  // MARK: - Helper Methods for Displaying Names and Colors

  // ゴミのタイプ名を返す
  String getGarbageTypeName(GarbageType type) {
    switch (type) {
      case GarbageType.burnable: return '燃えるごみ';
      case GarbageType.nonBurnable: return '燃えないごみ';
      case GarbageType.plastic: return 'プラスチック';
      case GarbageType.paper: return '紙';
      case GarbageType.cardboard: return '段ボール';
      case GarbageType.bottlesCans: return 'びん・かん';
      case GarbageType.petBottles: return 'ペットボトル';
      case GarbageType.hazardous: return '危険ごみ';
      case GarbageType.recyclable: return '資源ごみ（その他）';
    }
  }

  // ゴミのタイプに応じた色を返す
  Color getGarbageTypeColor(GarbageType type) {
    switch (type) {
      case GarbageType.burnable: return Colors.red[700]!;
      case GarbageType.nonBurnable: return Colors.blue[700]!;
      case GarbageType.plastic: return Colors.orange[700]!;
      case GarbageType.paper: return Colors.brown[700]!;
      case GarbageType.cardboard: return Colors.grey[700]!;
      case GarbageType.bottlesCans: return Colors.green[700]!;
      case GarbageType.petBottles: return Colors.lightBlue[700]!;
      case GarbageType.hazardous: return Colors.purple[700]!;
      case GarbageType.recyclable: return Colors.teal[700]!;
    }
  }

  // 収集頻度名を返す
  String getFrequencyName(CollectionFrequency frequency) {
    switch (frequency) {
      case CollectionFrequency.weekly: return '毎週';
      case CollectionFrequency.firstWeek: return '第1週目';
      case CollectionFrequency.secondWeek: return '第2週目';
      case CollectionFrequency.thirdWeek: return '第3週目';
      case CollectionFrequency.fourthWeek: return '第4週目';
      case CollectionFrequency.fifthWeek: return '第5週目';
    }
  }

  // 単一の曜日名を返す
  String getWeekdayName(Weekday weekday) {
    switch (weekday) {
      case Weekday.none: return '設定しない';
      case Weekday.monday: return '月曜日';
      case Weekday.tuesday: return '火曜日';
      case Weekday.wednesday: return '水曜日';
      case Weekday.thursday: return '木曜日';
      case Weekday.friday: return '金曜日';
      case Weekday.saturday: return '土曜日';
      case Weekday.sunday: return '日曜日';
    }
  }

  // 複数選択された曜日名を結合して表示するためのヘルパー
  String getWeekdayNames(Set<Weekday> weekdays) {
    if (weekdays.isEmpty) {
      return '未設定';
    }
    // 表示順を固定するためにソート
    final List<Weekday> sortedOrder = [
      Weekday.monday,
      Weekday.tuesday,
      Weekday.wednesday,
      Weekday.thursday,
      Weekday.friday,
      Weekday.saturday,
      Weekday.sunday,
    ];

    final List<String> names = [];
    for (var day in sortedOrder) {
      if (weekdays.contains(day)) {
        names.add(getWeekdayName(day));
      }
    }
    return names.join(', ');
  }
}