enum RescueType {
  hero,
  enemy,
  water,
  lava,
  stone,
  gold,
  pin,
  empty,
  exit,
  sand,
  hazard,
}

class RescueItem {
  final String id;
  RescueType type;
  int row;
  int col;

  RescueItem({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
  });

  @override
  String toString() => 'RescueItem(id: $id, type: $type, row: $row, col: $col)';
}
