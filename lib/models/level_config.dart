import '../models/rescue_item.dart';
import '../models/monster.dart';

enum GameMode {
  battle,
  rescue,
}

class LevelConfig {
  final int levelNumber;
  final GameMode mode;
  final int maxMoves;
  final int worldIndex; // 0..3
  final int targetScore;
  final String? backgroundAsset;

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
    this.targetScore = 0,
    this.backgroundAsset,
    this.monsterConfig,
    this.rescueLayout,
    this.targetEnergy,
  });

  factory LevelConfig.fromJson(Map<String, dynamic> json) {
    GameMode mode = json['mode'] == 'rescue' ? GameMode.rescue : GameMode.battle;

    // Parse Monster
    Monster? monster;
    if (json['monster'] != null) {
      monster = Monster(
        name: json['monster']['name'],
        maxHp: json['monster']['hp'] ?? 100,
        currentHp: json['monster']['hp'] ?? 100,
        level: json['id'],
        abilityCooldown: 4, // Default
      );
    }

    // Parse Rescue Layout
    List<List<RescueType>>? rescueLayout;
    if (json['rescueLayout'] != null) {
      rescueLayout = [];
      for (var row in json['rescueLayout']) {
        List<RescueType> r = [];
        for (var cell in row) {
          r.add(_parseRescueType(cell.toString()));
        }
        rescueLayout.add(r);
      }
    }

    return LevelConfig(
      levelNumber: json['id'],
      mode: mode,
      maxMoves: json['maxMoves'] ?? 20,
      worldIndex: json['world'] ?? 0,
      targetScore: json['targetScore'] ?? 0,
      backgroundAsset: json['background'],
      monsterConfig: monster,
      targetEnergy: json['targetEnergy'],
      rescueLayout: rescueLayout,
    );
  }

  static RescueType _parseRescueType(String type) {
    switch (type) {
      case 'pin': return RescueType.pin;
      case 'hero': return RescueType.hero;
      case 'stone': return RescueType.stone;
      case 'sand': return RescueType.sand;
      case 'gold': return RescueType.gold;
      case 'enemy': return RescueType.enemy;
      case 'lava': return RescueType.lava;
      case 'water': return RescueType.water;
      case 'exit': return RescueType.exit;
      case 'hazard': return RescueType.hazard;
      default: return RescueType.empty;
    }
  }
}
