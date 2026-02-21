import '../models/level_config.dart';
import '../models/monster.dart';
import '../models/rescue_item.dart';

List<LevelConfig> getLevels() {
  List<LevelConfig> levels = [];
  for (int i = 1; i <= 40; i++) {
    int worldIndex = (i - 1) ~/ 10;
    bool isBoss = i % 10 == 0;
    bool isRescue = (i % 5 == 2); // Levels 2, 7, 12, 17...

    if (isRescue) {
      levels.add(LevelConfig(
        levelNumber: i,
        mode: GameMode.rescue,
        maxMoves: 15 + (i ~/ 2),
        worldIndex: worldIndex,
        targetEnergy: 50 + (i * 5),
        rescueLayout: _generateRescueLayout(i),
      ));
    } else {
      // Battle Mode
      int hp = 100 + (i - 1) * 50;
      if (isBoss) hp *= 2;
      String monsterName = _getMonsterName(worldIndex, isBoss);

      levels.add(LevelConfig(
        levelNumber: i,
        mode: GameMode.battle,
        maxMoves: 15 + (i ~/ 2) + (isBoss ? 5 : 0),
        worldIndex: worldIndex,
        monsterConfig: Monster(
          name: monsterName,
          maxHp: hp,
          currentHp: hp,
          level: i,
          abilityCooldown: isBoss ? 2 : 4,
        ),
      ));
    }
  }
  return levels;
}

String _getMonsterName(int worldIndex, bool isBoss) {
  List<String> worldMonsters = [
    "Goblin", "Orc", "Skeleton", "Dark Knight"
  ];
  List<String> worldBosses = [
    "Goblin King", "Fire Dragon", "Hydra", "Dark Lord"
  ];
  if (isBoss) return worldBosses[worldIndex];
  return worldMonsters[worldIndex];
}

List<List<RescueType>> _generateRescueLayout(int level) {
  // Simple 5x5 layout depending on level roughly
  // P = Pin, H = Hero, E = Enemy, W = Water, L = Lava, X = Exit, . = Empty
  // New: S = Stone, D = Sand, Z = Hazard

  if (level % 2 == 0) {
     // Variation A
     return [
      [RescueType.stone, RescueType.hero, RescueType.stone, RescueType.hazard, RescueType.stone],
      [RescueType.pin, RescueType.sand, RescueType.pin, RescueType.pin, RescueType.pin],
      [RescueType.empty, RescueType.empty, RescueType.sand, RescueType.empty, RescueType.empty],
      [RescueType.pin, RescueType.pin, RescueType.pin, RescueType.pin, RescueType.pin],
      [RescueType.stone, RescueType.exit, RescueType.stone, RescueType.exit, RescueType.stone],
    ];
  } else {
    // Variation B
     return [
      [RescueType.gold, RescueType.hero, RescueType.gold, RescueType.stone, RescueType.sand],
      [RescueType.pin, RescueType.pin, RescueType.pin, RescueType.pin, RescueType.pin],
      [RescueType.enemy, RescueType.sand, RescueType.empty, RescueType.sand, RescueType.enemy],
      [RescueType.pin, RescueType.pin, RescueType.pin, RescueType.pin, RescueType.pin],
      [RescueType.stone, RescueType.exit, RescueType.exit, RescueType.exit, RescueType.stone],
    ];
  }
}
