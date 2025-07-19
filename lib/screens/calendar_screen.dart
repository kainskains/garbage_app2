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
    Weekday.none: -1, // 未設定の場合
  };

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<GarbageCollectionSettings>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ごみ収集カレンダー'),
        backgroundColor: Colors.blueAccent, // カレンダー画面の色を変えても良い
      ),
      body: SingleChildScrollView( // スクロール可能にする
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
                eventLoader: (day) {
                  List<String> events = [];
                  settingsProvider.settings.forEach((type, weekday) {
                    if (weekday != Weekday.none && _weekdayToDateTimeConstant[weekday] == day.weekday) {
                      events.add(settingsProvider.getGarbageTypeName(type));
                    }
                  });
                  return events;
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: _buildEventsMarker(events.length),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              // 選択された日の詳細表示 (オプション)
              if (_selectedDay != null)
                _buildSelectedDayEvents(settingsProvider, _selectedDay!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsMarker(int eventCount) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green[700],
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '$eventCount',
          style: const TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  // 選択された日のイベントを表示するウィジェット
  Widget _buildSelectedDayEvents(GarbageCollectionSettings settingsProvider, DateTime selectedDay) {
    final List<String> events = settingsProvider.settings.entries
        .where((entry) =>
    entry.value != Weekday.none &&
        _weekdayToDateTimeConstant[entry.value] == selectedDay.weekday)
        .map((entry) => settingsProvider.getGarbageTypeName(entry.key))
        .toList();

    if (events.isEmpty) {
      return Center(
        child: Text(
          '${selectedDay.month}月${selectedDay.day}日は収集物がありません。',
          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${selectedDay.month}月${selectedDay.day}日の収集物:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...events.map((event) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 10, color: Colors.blue),
                const SizedBox(width: 8),
                Text(event, style: const TextStyle(fontSize: 16)),
              ],
            ),
          )).toList(),
        ],
      );
    }
  }
}