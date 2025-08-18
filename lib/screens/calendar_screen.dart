// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';
import 'package:garbage_app/models/garbage_type.dart'; // GarbageTypeクラスをインポート

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
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<GarbageCollectionSettings>(context);
    final List<MapEntry<String, String?>> selectedDayGarbageInfo = _getGarbageInfoForDay(settingsProvider, _selectedDay ?? _focusedDay);

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
                    final List<MapEntry<String, String?>> dayGarbageInfo = _getGarbageInfoForDay(settingsProvider, day);
                    if (dayGarbageInfo.isNotEmpty) {
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Row(
                          children: dayGarbageInfo.map((entry) => _buildGarbageTypeMarker(settingsProvider.getGarbageTypeColor(entry.key))).toList(),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildSelectedDayEvents(settingsProvider, selectedDayGarbageInfo, _selectedDay ?? _focusedDay),
            ],
          ),
        ),
      ),
    );
  }

  // 特定の日のゴミタイプと時間を取得するヘルパーメソッド
  List<MapEntry<String, String?>> _getGarbageInfoForDay(GarbageCollectionSettings settingsProvider, DateTime day) {
    List<MapEntry<String, String?>> info = [];

    if (day == null) {
      return info;
    }

    settingsProvider.settings.forEach((typeId, rule) {
      if (rule.frequencies.isEmpty && rule.weekdays.isEmpty) {
        return;
      }
      if (rule.frequencies.isEmpty || rule.weekdays.isEmpty) {
        return;
      }

      final currentDayWeekday = Weekday.values.firstWhere(
            (w) => _weekdayToDateTimeConstant[w] == day.weekday,
        orElse: () => Weekday.none,
      );

      if (rule.weekdays.contains(currentDayWeekday)) {
        final int weekOfMonth = ((day.day - 1) / 7).floor() + 1;

        bool matchesFrequency = false;
        if (rule.frequencies.contains(CollectionFrequency.weekly)) {
          matchesFrequency = true;
        } else {
          if (rule.frequencies.contains(CollectionFrequency.firstWeek) && weekOfMonth == 1) {
            matchesFrequency = true;
          }
          if (rule.frequencies.contains(CollectionFrequency.secondWeek) && weekOfMonth == 2) {
            matchesFrequency = true;
          }
          if (rule.frequencies.contains(CollectionFrequency.thirdWeek) && weekOfMonth == 3) {
            matchesFrequency = true;
          }
          if (rule.frequencies.contains(CollectionFrequency.fourthWeek) && weekOfMonth == 4) {
            matchesFrequency = true;
          }
          if (rule.frequencies.contains(CollectionFrequency.fifthWeek) && weekOfMonth == 5) {
            matchesFrequency = true;
          }
        }

        if (matchesFrequency) {
          info.add(MapEntry(typeId, rule.timeOfDay));
        }
      }
    });
    return info;
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
  Widget _buildSelectedDayEvents(GarbageCollectionSettings settingsProvider, List<MapEntry<String, String?>> garbageInfo, DateTime day) {
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
        if (garbageInfo.isEmpty)
          Center(
            child: Text(
              'この日は収集物がありません。',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
          )
        else
          ...garbageInfo.map((entry) {
            final String typeId = entry.key;
            final String? time = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: settingsProvider.getGarbageTypeColor(typeId)),
                  const SizedBox(width: 8),
                  Text(
                    '${settingsProvider.getGarbageTypeName(typeId)} ${time != null ? '($time)' : ''}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}