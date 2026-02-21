enum TileType {
  red,
  blue,
  green,
  yellow,
  purple,
  empty, // For empty spaces
}

class Tile {
  final String id;
  TileType type;
  int row;
  int col;
  bool isBomb;

  Tile({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
    this.isBomb = false,
  });

  @override
  String toString() => 'Tile(id: $id, type: $type, row: $row, col: $col, isBomb: $isBomb)';
}
