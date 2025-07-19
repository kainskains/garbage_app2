// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<Weekday, int> _weekdayToDateTimeConstant = {
    Weekday.monday: DateTime.monday,
    Weekday.tuesday: DateTime.tuesday,
    Weekday.wednesday: DateTime.wednesday,
    Weekday.thursday: DateTime.thursday,
    Weekday.friday: DateTime.friday,
    Weekday.saturday: DateTime.saturday,
    Weekday.sunday: DateTime.sunday,
    Weekday.none: -1,
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // 初期選択日を今日に設定
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<GarbageCollectionSettings>(context);

    // 選択された日のイベントを計算
    final List<GarbageType> selectedDayGarbageTypes = _getGarbageTypesForDay(settingsProvider, _selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ごみ収集カレンダー'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final List<GarbageType> dayGarbageTypes = _getGarbageTypesForDay(settingsProvider, day);
                    if (dayGarbageTypes.isNotEmpty) {
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        // ゴミのタイプごとに色付きのマーカーを表示
                        child: Row(
                          children: dayGarbageTypes.map((type) => _buildGarbageTypeMarker(settingsProvider.getGarbageTypeColor(type))).toList(),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              // 選択された日の詳細表示
              _buildSelectedDayEvents(settingsProvider, selectedDayGarbageTypes, _selectedDay ?? _focusedDay),
            ],
          ),
        ),
      ),
    );
  }

  // 特定の日のゴミタイプを取得するヘルパーメソッド
  List<GarbageType> _getGarbageTypesForDay(GarbageCollectionSettings settingsProvider, DateTime day) {
    List<GarbageType> types = [];

    if (day == null) {
      return types;
    }

    settingsProvider.settings.forEach((type, rule) {
      if (rule.frequency == CollectionFrequency.none || rule.weekday == Weekday.none) {
        return; // このルールはスキップ
      }

      if (_weekdayToDateTimeConstant[rule.weekday] == day.weekday) {
        final firstDayOfMonth = DateTime(day.year, day.month, 1);
        final startOfFirstWeek = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - DateTime.monday));
        final daysSinceFirstWeekStart = day.difference(startOfFirstWeek).inDays;
        final int weekOfMonth = (daysSinceFirstWeekStart / 7).floor() + 1;

        bool matchesFrequency = false;
        switch (rule.frequency) {
          case CollectionFrequency.weekly:
            matchesFrequency = true;
            break;
          case CollectionFrequency.firstWeek:
            matchesFrequency = (weekOfMonth == 1);
            break;
          case CollectionFrequency.secondWeek:
            matchesFrequency = (weekOfMonth == 2);
            break;
          case CollectionFrequency.thirdWeek:
            matchesFrequency = (weekOfMonth == 3);
            break;
          case CollectionFrequency.fourthWeek:
            matchesFrequency = (weekOfMonth == 4);
            break;
          case CollectionFrequency.none:
            matchesFrequency = false;
            break;
        }

        if (matchesFrequency) {
          types.add(type);
        }
      }
    });
    return types;
  }

  // ゴミの種類ごとの色付きマーカー
  Widget _buildGarbageTypeMarker(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      width: 8.0,
      height: 8.0,
    );
  }

  // 選択された日のイベントを表示するウィジェット
  Widget _buildSelectedDayEvents(GarbageCollectionSettings settingsProvider, List<GarbageType> garbageTypes, DateTime day) {
    final List<String> eventNames = garbageTypes.map((type) => settingsProvider.getGarbageTypeName(type)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${day.month}月${day.day}日 (${settingsProvider.getWeekdayName(
              Weekday.values.firstWhere((w) => _weekdayToDateTimeConstant[w] == day.weekday, orElse: () => Weekday.none)
          )}):',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (eventNames.isEmpty)
          Center(
            child: Text(
              'この日は収集物がありません。',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
          )
        else
          ...eventNames.map((name) {
            // ゴミタイプ名から元のGarbageTypeを逆引きして色を取得
            final garbageType = settingsProvider.settings.keys.firstWhere(
                    (element) => settingsProvider.getGarbageTypeName(element) == name,
                orElse: () => GarbageType.other // 見つからない場合のフォールバック
            );
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: settingsProvider.getGarbageTypeColor(garbageType)),
                  const SizedBox(width: 8),
                  Text(name, style: const TextStyle(fontSize: 16)),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}