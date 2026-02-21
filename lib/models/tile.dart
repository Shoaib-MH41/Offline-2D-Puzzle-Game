enum TileType {
  sword,
  shield,
  crystal,
  heart,
  bomb,
  stone,
  ice,
  poison,
  empty,
  key,
  timedBomb,
  power,
  rocket,
  lamp,
}

class Tile {
  final String id;
  TileType type;
  int row;
  int col;
  int hp; // For stone (2 hits)
  bool isFrozen; // For ice
  bool isLocked; // For monster ability "Lock row"
  int maxTurns; // For timed bomb
  int turnsLeft; // For timed bomb

  Tile({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
    this.hp = 0,
    this.isFrozen = false,
    this.isLocked = false,
    this.maxTurns = 0,
    this.turnsLeft = 0,
  });

  bool get isBomb => type == TileType.bomb;
  bool get isPower => type == TileType.power;
  bool get isTimedBomb => type == TileType.timedBomb;
  bool get isRocket => type == TileType.rocket;
  bool get isLamp => type == TileType.lamp;

  @override
  String toString() => 'Tile(id: $id, type: $type, row: $row, col: $col, hp: $hp, locked: $isLocked)';
}
