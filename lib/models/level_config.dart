import 'package:puzzle_game/models/rescue_item.dart';
import 'package:puzzle_game/models/monster.dart';

enum GameMode {
  battle,
  rescue,
}

class LevelConfig {
  final int levelNumber;
  final GameMode mode;
  final int maxMoves;
  final int worldIndex; // 0..3

  // Battle Mode properties
  final Monster? monsterConfig;

  // Rescue Mode properties
  final List<List<RescueType>>? rescueLayout;
  final int? targetEnergy;

  const LevelConfig({
    required this.levelNumber,
    required this.mode,
    required this.maxMoves,
    required this.worldIndex,
    this.monsterConfig,
    this.rescueLayout,
    this.targetEnergy,
  });
}
