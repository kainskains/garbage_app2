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

// 曜日を定義するEnum
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
  fifthWeek,    // ★追加: 第5週目★
  // 必要であれば fifthWeek なども追加
  // none は頻度選択では使わない（全体ルール未設定はCollectionRuleオブジェクト自体がない場合で判断）
}

// 個々の収集日設定のエントリを表現するクラス
class CollectionRule {
  // ★変更点: frequency を Set<CollectionFrequency> に変更★
  Set<CollectionFrequency> frequencies;
  Weekday weekday;

  CollectionRule({required this.frequencies, this.weekday = Weekday.none});

  // 初期値としての空のルール
  CollectionRule.empty() : frequencies = <CollectionFrequency>{}, weekday = Weekday.none;


  // JSONからCollectionRuleオブジェクトを生成
  factory CollectionRule.fromJson(Map<String, dynamic> json) {
    // frequencies を List<String> から Set<CollectionFrequency> に変換
    final List<dynamic> freqStrings = json['frequencies'] as List<dynamic>;
    final Set<CollectionFrequency> freqs = freqStrings.map((s) => CollectionFrequency.values.firstWhere(
          (e) => e.toString().split('.').last == s,
      // デフォルト値は設定しない。データがおかしい場合は空セットで。
    )).toSet();

    return CollectionRule(
      frequencies: freqs,
      weekday: Weekday.values.firstWhere(
            (e) => e.toString().split('.').last == json['weekday'],
        orElse: () => Weekday.none,
      ),
    );
  }

  // CollectionRuleオブジェクトからJSONを生成
  Map<String, dynamic> toJson() {
    return {
      // Set<CollectionFrequency> を List<String> に変換して保存
      'frequencies': frequencies.map((f) => f.toString().split('.').last).toList(),
      'weekday': weekday.toString().split('.').last,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CollectionRule &&
              runtimeType == other.runtimeType &&
              setEquals(frequencies, other.frequencies) && // Setの比較には collection パッケージの setEquals を使用
              weekday == other.weekday;

  @override
  int get hashCode => frequencies.hashCode ^ weekday.hashCode;
}

// 収集日設定を管理するクラス
class GarbageCollectionSettings with ChangeNotifier {
  Map<GarbageType, CollectionRule> _settings = {
    GarbageType.cardboard: CollectionRule.empty(), // 初期化を empty rule に変更
    GarbageType.glass: CollectionRule.empty(),
    GarbageType.metal: CollectionRule.empty(),
    GarbageType.paper: CollectionRule.empty(),
    GarbageType.plastic: CollectionRule.empty(),
    GarbageType.other: CollectionRule.empty(),
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

  // 頻度セットを更新するヘルパーメソッドを追加
  void updateCollectionFrequencies(GarbageType type, Set<CollectionFrequency> newFrequencies) {
    final currentRule = _settings[type] ?? CollectionRule.empty();
    _settings[type] = CollectionRule(frequencies: newFrequencies, weekday: currentRule.weekday);
    saveSettings();
    notifyListeners();
  }

  // 曜日を更新するヘルパーメソッド (既存のupdateCollectionRuleと連携)
  void updateCollectionWeekday(GarbageType type, Weekday newWeekday) {
    final currentRule = _settings[type] ?? CollectionRule.empty();
    _settings[type] = CollectionRule(frequencies: currentRule.frequencies, weekday: newWeekday);
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

  // 収集頻度の日本語名を取得するメソッド
  // CollectionFrequency.none は頻度選択には使わないため、リストからは除外
  String getFrequencyName(CollectionFrequency frequency) {
    switch (frequency) {
      case CollectionFrequency.weekly: return '毎週';
      case CollectionFrequency.firstWeek: return '第1週目';
      case CollectionFrequency.secondWeek: return '第2週目';
      case CollectionFrequency.thirdWeek: return '第3週目';
      case CollectionFrequency.fourthWeek: return '第4週目';
      case CollectionFrequency.fifthWeek: return '第5週目'; // ★追加: 第5週目★
    // case CollectionFrequency.none: return '未設定'; // ここは不要
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