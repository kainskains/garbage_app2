// lib/models/garbage_type.dart
import 'package:flutter/material.dart';

class GarbageType {
  final String type;
  final String name;
  final IconData icon;

  GarbageType({
    required this.type,
    required this.name,
    required this.icon,
  });

  factory GarbageType.fromJson(Map<String, dynamic> json) {
    return GarbageType(
      type: json['type'] as String,
      name: json['name'] as String,
      icon: IconData(json['icon_code_point'] as int, fontFamily: 'MaterialIcons'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'icon_code_point': icon.codePoint,
    };
  }
}