// lib/utils/app_utils.dart

import 'package:garbage_app/models/monster.dart'; // MonsterAttributeを使うため

class AppUtils {
  static String getAttributeJapaneseName(MonsterAttribute attribute) {
    switch (attribute) {
      case MonsterAttribute.fire: return '炎';
      case MonsterAttribute.water: return '水';
      case MonsterAttribute.wood: return '木';
      case MonsterAttribute.light: return '光';
      case MonsterAttribute.dark: return '闇';
      case MonsterAttribute.none: return 'なし';
    }
  }
}