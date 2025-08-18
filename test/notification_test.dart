// test/notification_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:garbage_app/services/notification_service.dart';
import 'notification_test.mocks.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late NotificationService notificationService;

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    when(mockPlugin.initialize(
      any,
      onDidReceiveBackgroundNotificationResponse: anyNamed('onDidReceiveBackgroundNotificationResponse'),
      onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse'),
    )).thenAnswer((_) async => true);
    notificationService = NotificationService(flutterLocalNotificationsPlugin: mockPlugin);
  });

  group('NotificationService', () {
    test('通知が正しい時刻にスケジュールされるか', () async {
      final collectionDate = tz.TZDateTime.local(2025, 8, 25, 8, 0);
      final scheduledDate = collectionDate.subtract(const Duration(minutes: 60));

      when(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).thenAnswer((_) async {});

      await notificationService.scheduleGarbageNotification(
        1,
        'ごみ収集',
        '明日は燃えるごみの日です',
        collectionDate,
        60,
      );

      verify(mockPlugin.zonedSchedule(
        1,
        'ごみ収集',
        '明日は燃えるごみの日です',
        tz.TZDateTime.from(scheduledDate, tz.local),
        any,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      )).called(1);
    });

    test('通知時刻の調整がない場合に、収集時刻がそのまま使用されるか', () async {
      final collectionDate = tz.TZDateTime.local(2025, 8, 26, 7, 30);

      when(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).thenAnswer((_) async {});

      await notificationService.scheduleGarbageNotification(
        2,
        '資源ごみ',
        '今日は資源ごみの日です',
        collectionDate,
        null,
      );

      verify(mockPlugin.zonedSchedule(
        2,
        '資源ごみ',
        '今日は資源ごみの日です',
        tz.TZDateTime.from(collectionDate, tz.local),
        any,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      )).called(1);
    });

    test('cancelAllNotificationsが正しく呼ばれるか', () async {
      when(mockPlugin.cancelAll()).thenAnswer((_) async {});

      await notificationService.cancelAllNotifications();

      verify(mockPlugin.cancelAll()).called(1);
    });
  });
}