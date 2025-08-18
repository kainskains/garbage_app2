import 'package:flutter/material.dart';

// ✅ CollectionFrequencyとWeekdayのenumをここに集約します
enum CollectionFrequency { weekly, firstWeek, secondWeek, thirdWeek, fourthWeek, fifthWeek, none }
enum Weekday { none, sunday, monday, tuesday, wednesday, thursday, friday, saturday }

class GarbageType {
  final String type;
  final String name;
  final IconData icon;
  final String? color;

  GarbageType({
    required this.type,
    required this.name,
    required this.icon,
    this.color,
  });

  factory GarbageType.fromJson(Map<String, dynamic> json) {
    return GarbageType(
      type: json['type'] as String,
      name: json['name'] as String,
      icon: _getIconData(json['icon'] as String),
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'icon': icon.codePoint.toString(),
      'color': color,
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