import 'package:shared_preferences/shared_preferences.dart';

import 'game/levels.dart';

/// حفظ التقدم (المستويات المفتوحة والنجوم). إن فشل التخزين تعمل اللعبة بالذاكرة فقط.
class Progress {
  static SharedPreferences? _p;
  static int _memUnlocked = 1;
  static final Map<int, int> _memStars = {};

  static Future<void> init() async {
    try {
      _p = await SharedPreferences.getInstance();
    } catch (_) {
      _p = null;
    }
  }

  static int get unlocked => _p?.getInt('unlocked') ?? _memUnlocked;

  static int starsOf(int level) => _p?.getInt('stars_$level') ?? _memStars[level] ?? 0;

  static int get totalStars {
    var sum = 0;
    for (var i = 1; i <= totalLevels; i++) {
      sum += starsOf(i);
    }
    return sum;
  }

  static Future<void> saveWin(int level, int stars) async {
    final best = stars > starsOf(level) ? stars : starsOf(level);
    final next = level + 1 > totalLevels ? totalLevels : level + 1;
    final newUnlocked = next > unlocked ? next : unlocked;
    _memStars[level] = best;
    _memUnlocked = newUnlocked;
    try {
      await _p?.setInt('stars_$level', best);
      await _p?.setInt('unlocked', newUnlocked);
    } catch (_) {}
  }
}
