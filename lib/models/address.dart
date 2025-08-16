// lib/models/address.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class City {
  final String name;
  final String? gomisakuId;

  City({required this.name, this.gomisakuId});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] as String,
      gomisakuId: json['gomisaku_id'] as String?,
    );
  }
}

class Prefecture {
  final String name;
  final List<City> cities;

  Prefecture({required this.name, required this.cities});

  factory Prefecture.fromJson(Map<String, dynamic> json) {
    var citiesList = json['cities'] as List;
    List<City> cities = citiesList.map((i) => City.fromJson(i as Map<String, dynamic>)).toList();
    return Prefecture(
      name: json['prefecture'] as String,
      cities: cities,
    );
  }
}

class Region {
  final String name;
  final List<Prefecture> prefectures;

  Region({required this.name, required this.prefectures});

  factory Region.fromJson(Map<String, dynamic> json) {
    var prefecturesList = json['prefectures'] as List;
    List<Prefecture> prefectures = prefecturesList.map((i) => Prefecture.fromJson(i as Map<String, dynamic>)).toList();
    return Region(
      name: json['region'] as String,
      prefectures: prefectures,
    );
  }
}