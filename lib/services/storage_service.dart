import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyHighScore = 'high_score';
  static const String _keyHighestLevel = 'highest_level';
  static const String _keyStars = 'level_stars_'; // + level

  Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyHighScore) ?? 0;
  }

  Future<void> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = prefs.getInt(_keyHighScore) ?? 0;
    if (score > currentHigh) {
      await prefs.setInt(_keyHighScore, score);
    }
  }

  Future<int> getHighestLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyHighestLevel) ?? 1;
  }

  Future<void> unlockLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyHighestLevel) ?? 1;
    if (level > current) {
      await prefs.setInt(_keyHighestLevel, level);
    }
  }

  Future<int> getLevelStars(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyStars$level') ?? 0;
  }

  Future<void> saveLevelStars(int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('$_keyStars$level') ?? 0;
    if (stars > current) {
      await prefs.setInt('$_keyStars$level', stars);
    }
  }
}
