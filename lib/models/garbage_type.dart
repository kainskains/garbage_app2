// lib/models/garbage_type.dart
import 'package:flutter/material.dart';

class GarbageType {
  final String type;
  final String name;
  final IconData icon;
  final String? color; // ★追加: 色の情報を保持するプロパティ★

  GarbageType({
    required this.type,
    required this.name,
    required this.icon,
    this.color, // ★追加: コンストラクタに含める★
  });

  factory GarbageType.fromJson(Map<String, dynamic> json) {
    return GarbageType(
      type: json['type'] as String,
      name: json['name'] as String,
      icon: _getIconData(json['icon'] as String),
      color: json['color'] as String?, // ★追加: JSONからcolorを読み込む★
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'icon': icon.codePoint.toString(),
      'color': color, // ★追加: JSONにcolorを書き込む★
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is GarbageType && runtimeType == other.runtimeType && type == other.type;

  @override
  int get hashCode => type.hashCode;

  static IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'delete_forever':
        return Icons.delete_forever;
      case 'recycling':
        return Icons.recycling;
      case 'grass':
        return Icons.grass;
      case 'work':
        return Icons.work;
      case 'auto_awesome':
        return Icons.auto_awesome;
      default:
        return Icons.error;
    }
  }
}