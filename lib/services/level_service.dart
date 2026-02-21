import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/level_config.dart';

class LevelService {
  List<LevelConfig> _levels = [];

  Future<void> loadLevels() async {
    try {
      final String response = await rootBundle.loadString('assets/levels.json');
      final List<dynamic> data = json.decode(response);
      _levels = data.map((json) => LevelConfig.fromJson(json)).toList();
    } catch (e) {
      // debugPrint("Error loading levels: $e");
      // Fallback or empty
    }
  }

  LevelConfig getLevel(int levelNumber) {
    return _levels.firstWhere(
      (l) => l.levelNumber == levelNumber,
      orElse: () => _levels.isNotEmpty ? _levels.last : _createDefaultLevel(levelNumber),
    );
  }

  int get totalLevels => _levels.length;

  LevelConfig _createDefaultLevel(int levelNumber) {
    // Basic fallback
    return LevelConfig(
      levelNumber: levelNumber,
      mode: GameMode.battle,
      maxMoves: 20,
      worldIndex: 0,
      targetScore: 1000,
    );
  }
}
