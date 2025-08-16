// lib/services/address_service.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:garbage_app/models/address.dart';

class AddressService {
  static List<Region> _allRegions = [];

  static Future<void> loadAddresses() async {
    if (_allRegions.isNotEmpty) return;
    try {
      final String jsonString = await rootBundle.loadString('assets/addresses.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _allRegions = jsonList.map((json) => Region.fromJson(json as Map<String, dynamic>)).toList();
      print('住所データを読み込みました');
    } catch (e) {
      print('住所データの読み込みに失敗しました: $e');
    }
  }

  static List<String> getRegions() {
    return _allRegions.map((r) => r.name).toList();
  }

  static List<String> getPrefecturesForRegion(String regionName) {
    try {
      final region = _allRegions.firstWhere((r) => r.name == regionName);
      return region.prefectures.map((p) => p.name).toList();
    } catch (e) {
      return [];
    }
  }

  static List<String> getCitiesForPrefecture(String prefectureName) {
    try {
      final prefecture = _allRegions
          .expand((r) => r.prefectures)
          .firstWhere((p) => p.name == prefectureName);
      return prefecture.cities.map((c) => c.name).toList();
    } catch (e) {
      return [];
    }
  }

  static String? getGomisakuIdForCity(String prefectureName, String cityName) {
    try {
      final prefecture = _allRegions
          .expand((r) => r.prefectures)
          .firstWhere((p) => p.name == prefectureName);
      final city = prefecture.cities.firstWhere((c) => c.name == cityName);
      return city.gomisakuId;
    } catch (e) {
      return null;
    }
  }
}