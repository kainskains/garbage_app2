// test/garbage_collection_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:garbage_app/models/garbage_type.dart';
import 'package:garbage_app/models/garbage_collection_settings.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/material.dart';

// ✅ shared_preferences をインポート
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // テストの前にタイムゾーンを初期化
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    // ✅ shared_preferences のモックを設定
    SharedPreferences.setMockInitialValues({});
  });

  group('GarbageCollectionSettings', () {
    test('「毎週月曜日、午前8時」の収集日時を正しく計算する', () {
      final settings = GarbageCollectionSettings();
      final testTypeId = 'test_burnable';

      settings.addGarbageType(GarbageType(type: testTypeId, name: 'テストごみ', icon: Icons.local_fire_department));
      settings.updateCollectionRule(
        testTypeId,
        CollectionRule(
          frequencies: {CollectionFrequency.weekly},
          weekdays: {Weekday.monday},
          timeOfDay: '08:00',
        ),
      );

      final now = tz.TZDateTime.local(2025, 8, 23, 23, 0);
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

      final nextDateTime = settings.calculateNextCollectionDateTime(testTypeId);

      final expectedDateTime = tz.TZDateTime.local(2025, 8, 25, 8, 0);

      expect(nextDateTime, equals(expectedDateTime));
    });

    test('「第2、4週の木曜日、午前7時30分」の収集日時を正しく計算する', () {
      final settings = GarbageCollectionSettings();
      final testTypeId = 'test_recyclable';

      settings.addGarbageType(GarbageType(type: testTypeId, name: 'テスト資源ごみ', icon: Icons.recycling));
      settings.updateCollectionRule(
        testTypeId,
        CollectionRule(
          frequencies: {CollectionFrequency.secondWeek, CollectionFrequency.fourthWeek},
          weekdays: {Weekday.thursday},
          timeOfDay: '07:30',
        ),
      );

      final now = tz.TZDateTime.local(2025, 8, 26, 20, 0);
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

      final nextDateTime = settings.calculateNextCollectionDateTime(testTypeId);

      final expectedDateTime = tz.TZDateTime.local(2025, 8, 28, 7, 30);

      expect(nextDateTime, equals(expectedDateTime));
    });

    test('ルールが不完全な場合にnullを返す', () {
      final settings = GarbageCollectionSettings();
      final testTypeId = 'test_incomplete';

      settings.addGarbageType(GarbageType(type: testTypeId, name: '不完全なごみ', icon: Icons.error));
      settings.updateCollectionRule(
        testTypeId,
        CollectionRule(
          frequencies: {},
          weekdays: {Weekday.monday},
          timeOfDay: '09:00',
        ),
      );

      final nextDateTime = settings.calculateNextCollectionDateTime(testTypeId);

      expect(nextDateTime, isNull);
    });
  });
}