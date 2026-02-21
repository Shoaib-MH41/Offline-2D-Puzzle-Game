enum TileType {
  sword,
  shield,
  crystal,
  heart,
  bomb,
  empty,
}

class Tile {
  final String id;
  TileType type;
  int row;
  int col;

  Tile({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
  });

  bool get isBomb => type == TileType.bomb;

  @override
  String toString() => 'Tile(id: $id, type: $type, row: $row, col: $col)';
}
