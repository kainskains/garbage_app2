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
    // Weekday.none は DateTime.weekday に対応しないのでここでは不要
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
      // ルールが未設定（頻度も曜日もnone）の場合はスキップ
      if (rule.frequencies.isEmpty && rule.weekday == Weekday.none) {
        return;
      }
      // 頻度が設定されていない、または曜日が未設定の場合はスキップ (部分的な設定ミス防止)
      if (rule.frequencies.isEmpty || rule.weekday == Weekday.none) {
        return;
      }

      // 1. 設定された曜日とカレンダーの日の曜日が一致するか確認
      if (_weekdayToDateTimeConstant[rule.weekday] == day.weekday) {
        // 2. 曜日が一致した場合、さらに頻度をチェック

        // 月の1日を基準にした「第N週目」の計算
        // (日 - 1) を 7 で割って切り捨て、1を足すことで、
        // 1-7日を第1週、8-14日を第2週...とする
        final int weekOfMonth = ((day.day - 1) / 7).floor() + 1;

        bool matchesFrequency = false;
        // 毎週設定が含まれている場合、他の第X週目の設定は無視して常にtrue
        if (rule.frequencies.contains(CollectionFrequency.weekly)) {
          matchesFrequency = true;
        } else {
          // 個別の第X週目設定が含まれている場合、現在の日がその週に該当するかチェック
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
          if (rule.frequencies.contains(CollectionFrequency.fifthWeek) && weekOfMonth == 5) { // ★第5週目ロジック追加★
            matchesFrequency = true;
          }
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
      width: 8.0, // 小さめのドット
      height: 8.0,
    );
  }

  // 選択された日のイベントを表示するウィジェット
  Widget _buildSelectedDayEvents(GarbageCollectionSettings settingsProvider, List<GarbageType> garbageTypes, DateTime day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${day.month}月${day.day}日 (${settingsProvider.getWeekdayName(
            // Weekday.values.firstWhere(...): DateTime.weekday (int) から Weekday enum を逆引き
              Weekday.values.firstWhere((w) => _weekdayToDateTimeConstant[w] == day.weekday, orElse: () => Weekday.none)
          )}):',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // garbageTypes が空かどうかをチェック
        if (garbageTypes.isEmpty)
          Center(
            child: Text(
              'この日は収集物がありません。',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
          )
        else
        // garbageTypes リストを直接 map して、各要素 (type: GarbageType) を使う
          ...garbageTypes.map((type) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: settingsProvider.getGarbageTypeColor(type)), // type は GarbageType 型
                  const SizedBox(width: 8),
                  Text(settingsProvider.getGarbageTypeName(type), style: const TextStyle(fontSize: 16)), // type は GarbageType 型
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}