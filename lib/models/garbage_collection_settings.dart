// lib/models/garbage_collection_settings.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // JSONエンコード/デコード用

// ゴミの種類を定義するEnum
enum GarbageType {
  cardboard, // 段ボール
  glass,      // ガラス
  metal,      // 金属
  paper,      // 紙
  plastic,    // プラスチック
  other,      // その他
}

// 曜日を定義するEnum (FlutterのMaterial.dartにもDayOfWeekがあるが、シンプルに定義)
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

// 収集日設定を管理するクラス
class GarbageCollectionSettings with ChangeNotifier {
  // 各ゴミの種類と収集曜日のマップ
  Map<GarbageType, Weekday> _settings = {
    GarbageType.cardboard: Weekday.none,
    GarbageType.glass: Weekday.none,
    GarbageType.metal: Weekday.none,
    GarbageType.paper: Weekday.none,
    GarbageType.plastic: Weekday.none,
    GarbageType.other: Weekday.none,
  };

  Map<GarbageType, Weekday> get settings => _settings;

  // 設定を読み込む
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString('garbageCollectionSettings');

    if (settingsJson != null) {
      final Map<String, dynamic> decodedJson = json.decode(settingsJson);
      _settings = decodedJson.map((key, value) {
        return MapEntry(
          GarbageType.values.firstWhere((e) => e.toString().split('.').last == key),
          Weekday.values.firstWhere((e) => e.toString().split('.').last == value),
        );
      });
    }
    notifyListeners();
  }

  // 設定を保存する
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> encodedMap = _settings.map((key, value) {
      return MapEntry(
        key.toString().split('.').last, // Enum名を文字列に変換
        value.toString().split('.').last, // Enum名を文字列に変換
      );
    });
    await prefs.setString('garbageCollectionSettings', json.encode(encodedMap));
  }

  // 特定のゴミの収集日を更新する
  void updateCollectionDay(GarbageType type, Weekday day) {
    _settings[type] = day;
    saveSettings(); // 変更を即座に保存
    notifyListeners(); // UIを更新
  }

  // 日本語のゴミタイプ名を取得
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

  // 日本語の曜日名を取得
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
}