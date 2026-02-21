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
}

class Tile {
  final String id;
  TileType type;
  int row;
  int col;
  int hp; // For stone (2 hits)
  bool isFrozen; // For ice (1 hit adjacent) - Wait, if Ice is a type, do I need isFrozen?
                 // "Ice tile (must match adjacent to break)".
                 // If Ice is a type, then `type == TileType.ice`.
                 // So `isFrozen` might be redundant if `type` is enough.
                 // However, maybe `isFrozen` implies a normal tile is covered in ice?
                 // If it's "Ice tile", usually it's a blocker.
                 // Let's stick to `TileType.ice`.
                 // But wait, if I want to freeze a row, maybe I should use a property?
                 // "Lock random row". That's `isLocked`.
                 // "Ice tile" is an obstacle.
                 // So I'll use `TileType.ice`.
  bool isLocked; // For monster ability "Lock row"

  Tile({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
    this.hp = 0,
    this.isFrozen = false,
    this.isLocked = false,
  });

  bool get isBomb => type == TileType.bomb;

  @override
  String toString() => 'Tile(id: $id, type: $type, row: $row, col: $col, hp: $hp, locked: $isLocked)';
}
