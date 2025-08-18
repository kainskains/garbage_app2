// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:garbage_app/models/garbage_type.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> scheduleGarbageNotification(
      int id, String title, String body, DateTime scheduledDate) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'garbage_channel_id',
      'Garbage Collection Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
    DarwinNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ← この新しい必須パラメータを追加
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      // uiLocalNotificationDateInterpretation: // ❌ この行を削除します
      // UILocalNotificationDateInterpretation.absoluteTime, // ❌ この行を削除します
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
