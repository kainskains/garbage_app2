// lib/models/garbage_collection_settings.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

// ゴミの種類を定義するEnum
enum GarbageType {
  cardboard, // 段ボール
  glass,      // ガラス
  metal,      // 金属
  paper,      // 紙
  plastic,    // プラスチック
  other,      // その他
}

// 曜日を定義するEnum (これまで通り)
enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
  none, // 設定なしの場合
}

// 収集頻度を定義するEnum
enum CollectionFrequency {
  weekly,       // 毎週
  firstWeek,    // 第1週目
  secondWeek,   // 第2週目
  thirdWeek,    // 第3週目
  fourthWeek,   // 第4週目
  // 必要であれば fifthWeek なども追加
  none,         // 未設定
}

// 個々の収集日設定のエントリを表現するクラス
class CollectionRule {
  CollectionFrequency frequency;
  Weekday weekday;

  CollectionRule({this.frequency = CollectionFrequency.none, this.weekday = Weekday.none});

  // JSONからCollectionRuleオブジェクトを生成
  factory CollectionRule.fromJson(Map<String, dynamic> json) {
    return CollectionRule(
      frequency: CollectionFrequency.values.firstWhere(
            (e) => e.toString().split('.').last == json['frequency'],
        orElse: () => CollectionFrequency.none,
      ),
      weekday: Weekday.values.firstWhere(
            (e) => e.toString().split('.').last == json['weekday'],
        orElse: () => Weekday.none,
      ),
    );
  }

  // CollectionRuleオブジェクトからJSONを生成
  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.toString().split('.').last,
      'weekday': weekday.toString().split('.').last,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CollectionRule &&
              runtimeType == other.runtimeType &&
              frequency == other.frequency &&
              weekday == other.weekday;

  @override
  int get hashCode => frequency.hashCode ^ weekday.hashCode;
}

// 収集日設定を管理するクラス
class GarbageCollectionSettings with ChangeNotifier {
  // 各ゴミの種類と収集ルールのマップ
  Map<GarbageType, CollectionRule> _settings = {
    GarbageType.cardboard: CollectionRule(),
    GarbageType.glass: CollectionRule(),
    GarbageType.metal: CollectionRule(),
    GarbageType.paper: CollectionRule(),
    GarbageType.plastic: CollectionRule(),
    GarbageType.other: CollectionRule(),
  };

  Map<GarbageType, CollectionRule> get settings => _settings;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString('garbageCollectionSettings');

    if (settingsJson != null) {
      final Map<String, dynamic> decodedJson = json.decode(settingsJson);
      _settings = decodedJson.map((key, value) {
        return MapEntry(
          GarbageType.values.firstWhere((e) => e.toString().split('.').last == key),
          CollectionRule.fromJson(value), // CollectionRuleとしてデコード
        );
      });
    }
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> encodedMap = _settings.map((key, value) {
      return MapEntry(
        key.toString().split('.').last,
        value.toJson(), // CollectionRuleをJSONにエンコード
      );
    });
    await prefs.setString('garbageCollectionSettings', json.encode(encodedMap));
  }

  // 特定のゴミの収集日ルールを更新する
  void updateCollectionRule(GarbageType type, CollectionRule rule) {
    _settings[type] = rule;
    saveSettings();
    notifyListeners();
  }

  String getGarbageTypeName(GarbageType type) {
    switch (type) {
      case GarbageType.cardboard: return '段ボール';
      case GarbageType.glass: return 'ガラス';
      case GarbageType.metal: return '金属';
      case GarbageType.paper: return '紙';
      case GarbageType.plastic: return 'プラスチック';
      case GarbageType.other: return 'その他';
    }
  }

  String getWeekdayName(Weekday day) {
    switch (day) {
      case Weekday.monday: return '月曜日';
      case Weekday.tuesday: return '火曜日';
      case Weekday.wednesday: return '水曜日';
      case Weekday.thursday: return '木曜日';
      case Weekday.friday: return '金曜日';
      case Weekday.saturday: return '土曜日';
      case Weekday.sunday: return '日曜日';
      case Weekday.none: return '未設定';
    }
  }

  // ★追加: 収集頻度の日本語名を取得するメソッド★
  String getFrequencyName(CollectionFrequency frequency) {
    switch (frequency) {
      case CollectionFrequency.weekly: return '毎週';
      case CollectionFrequency.firstWeek: return '第1週目';
      case CollectionFrequency.secondWeek: return '第2週目';
      case CollectionFrequency.thirdWeek: return '第3週目';
      case CollectionFrequency.fourthWeek: return '第4週目';
      case CollectionFrequency.none: return '未設定';
    }
  }

  Color getGarbageTypeColor(GarbageType type) {
    switch (type) {
      case GarbageType.cardboard: return Colors.brown;
      case GarbageType.glass: return Colors.lightBlue;
      case GarbageType.metal: return Colors.grey;
      case GarbageType.paper: return Colors.yellow[700]!;
      case GarbageType.plastic: return Colors.green;
      case GarbageType.other: return Colors.deepPurple;
    }
  }
}