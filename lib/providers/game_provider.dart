import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/tile.dart';
import '../models/monster.dart';

enum Direction { up, down, left, right }

abstract class GameEvent {}

class ScoreEvent extends GameEvent {
  final int score;
  final int row;
  final int col;
  ScoreEvent(this.score, this.row, this.col);
}

class DamageEvent extends GameEvent {
  final int damage;
  DamageEvent(this.damage);
}

class BombEvent extends GameEvent {
  final int row;
  final int col;
  BombEvent(this.row, this.col);
}

class ShakeEvent extends GameEvent {}

class GameProvider with ChangeNotifier {
  static const int rows = 9;
  static const int cols = 7;

  List<List<Tile>> _grid = [];
  int _score = 0;
  bool _isProcessing = false;
  int _comboCount = 0;

  late Monster _monster;
  int _level = 1;

  final _eventController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventController.stream;

  List<List<Tile>> get grid => _grid;
  int get score => _score;
  bool get isProcessing => _isProcessing;
  int get comboCount => _comboCount;
  Monster get monster => _monster;
  int get level => _level;

  final Random _random = Random();

  GameProvider() {
    _initLevel();
    generateGrid();
  }

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }

  void _initLevel() {
    // Simple scaling: +50 HP per level
    int hp = 100 + (_level - 1) * 50;
    _monster = Monster(
      name: "Goblin",
      maxHp: hp,
      currentHp: hp,
      level: _level,
    );
  }

  void startNextLevel() {
    _level++;
    _initLevel();
    generateGrid();
  }

  void generateGrid() {
    _grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        return _createRandomTile(r, c);
      });
    });
    // TODO: Ensure no matches on start
    notifyListeners();
  }

  Tile _createRandomTile(int row, int col) {
    // Exclude empty and bomb from random generation
    final types = TileType.values.where((t) => t != TileType.empty && t != TileType.bomb).toList();
    final type = types[_random.nextInt(types.length)];
    return Tile(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(100000)}',
      type: type,
      row: row,
      col: col,
    );
  }

  Future<void> handleSwap(int row, int col, Direction direction) async {
    if (_isProcessing) return;

    _comboCount = 0; // Reset combo on new move

    int newRow = row;
    int newCol = col;

    switch (direction) {
      case Direction.up: newRow--; break;
      case Direction.down: newRow++; break;
      case Direction.left: newCol--; break;
      case Direction.right: newCol++; break;
    }

    // Bounds check
    if (newRow < 0 || newRow >= rows || newCol < 0 || newCol >= cols) return;

    final tileA = _grid[row][col];
    final tileB = _grid[newRow][newCol];

    if (tileA.type == TileType.empty || tileB.type == TileType.empty) return;

    _isProcessing = true;

    // 1. Swap
    _swapTiles(row, col, newRow, newCol);
    notifyListeners();

    // 2. Animate Swap
    await Future.delayed(const Duration(milliseconds: 300));

    // Check for Bomb interaction
    bool isBombInteraction = tileA.type == TileType.bomb || tileB.type == TileType.bomb;

    if (isBombInteraction) {
       if (tileA.type == TileType.bomb) await _triggerBomb(tileA);
       // Check tileB type again in case tileA explosion removed it (unlikely if strictly adjacent but possible in logic)
       // Since we just swapped, they are adjacent.
       // We'll just trigger tileB if it's a bomb and still exists (not empty)
       // Wait. tileA was at row,col. tileB was at newRow,newCol.
       // After swap: tileA is at newRow,newCol. tileB is at row,col.

       // So we check positions:
       final t1 = _grid[newRow][newCol]; // This is where tileA is
       final t2 = _grid[row][col];       // This is where tileB is

       if (t1.type == TileType.bomb) await _triggerBomb(t1);
       if (t2.type == TileType.bomb) await _triggerBomb(t2);

       await _processBoard();
    } else {
      // Normal Match Check
      final matches = _checkMatches();

      if (matches.isNotEmpty) {
         await _processBoard();
      } else {
        // Revert
        _swapTiles(row, col, newRow, newCol);
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300)); // Animate back
      }
    }

    _isProcessing = false;
  }

  void _swapTiles(int r1, int c1, int r2, int c2) {
    final temp = _grid[r1][c1];
    _grid[r1][c1] = _grid[r2][c2];
    _grid[r2][c2] = temp;

    // Update coordinates
    _grid[r1][c1].row = r1;
    _grid[r1][c1].col = c1;
    _grid[r2][c2].row = r2;
    _grid[r2][c2].col = c2;
  }

  List<List<Tile>> _checkMatches() {
    Set<Tile> matchedTiles = {};

    // Horizontal
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols - 2; c++) {
        final t1 = _grid[r][c];
        final t2 = _grid[r][c+1];
        final t3 = _grid[r][c+2];
        if (t1.type != TileType.empty && t1.type != TileType.bomb &&
            t1.type == t2.type && t1.type == t3.type) {
          matchedTiles.add(t1);
          matchedTiles.add(t2);
          matchedTiles.add(t3);
        }
      }
    }

    // Vertical
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows - 2; r++) {
        final t1 = _grid[r][c];
        final t2 = _grid[r+1][c];
        final t3 = _grid[r+2][c];
        if (t1.type != TileType.empty && t1.type != TileType.bomb &&
            t1.type == t2.type && t1.type == t3.type) {
          matchedTiles.add(t1);
          matchedTiles.add(t2);
          matchedTiles.add(t3);
        }
      }
    }

    return _findClusters(matchedTiles);
  }

  List<List<Tile>> _findClusters(Set<Tile> matchedTiles) {
    List<List<Tile>> clusters = [];
    Set<Tile> visited = {};

    for (var tile in matchedTiles) {
      if (!visited.contains(tile)) {
        List<Tile> cluster = [];
        List<Tile> queue = [tile];
        visited.add(tile);

        while (queue.isNotEmpty) {
          final current = queue.removeAt(0);
          cluster.add(current);

          final directions = [[-1, 0], [1, 0], [0, -1], [0, 1]];
          for (var dir in directions) {
            final nr = current.row + dir[0];
            final nc = current.col + dir[1];
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
              final neighbor = _grid[nr][nc];
              if (matchedTiles.contains(neighbor) && !visited.contains(neighbor) && neighbor.type == current.type) {
                visited.add(neighbor);
                queue.add(neighbor);
              }
            }
          }
        }
        clusters.add(cluster);
      }
    }
    return clusters;
  }

  Future<void> _processBoard() async {
    while (true) {
      final clusters = _checkMatches();
      if (clusters.isEmpty) break;

      _comboCount++;
      if (_comboCount > 1) {
         _eventController.add(ShakeEvent());
      }

      await _processMatches(clusters);

      await Future.delayed(const Duration(milliseconds: 300));
      _applyGravity();
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));
      _refill();
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _processMatches(List<List<Tile>> matchClusters) async {
    for (var cluster in matchClusters) {
      if (cluster.isEmpty) continue;

      int multiplier = _comboCount > 0 ? _comboCount : 1;
      int points = cluster.length * 10 * multiplier;
      int damage = cluster.length * multiplier; // Damage also scales? Or flat? Let's scale it slightly or keep flat. User said "Damage based on match size". Combo usually scales score.
      // "Add combo multiplier system". Usually implies score.
      // But "Damage monster based on match size".
      // I'll scale score by combo. Damage flat by size.

      final center = cluster[cluster.length ~/ 2];
      _eventController.add(ScoreEvent(points, center.row, center.col));
      _eventController.add(DamageEvent(damage));

      _score += points;
      _monster.currentHp -= damage;
      if (_monster.currentHp < 0) _monster.currentHp = 0;

      // Determine bomb creation
      Tile? bombTarget;
      if (cluster.length >= 5) {
         bombTarget = center;
      }

      for (var tile in cluster) {
         if (bombTarget != null && tile == bombTarget) {
            _grid[tile.row][tile.col] = Tile(
              id: 'bomb_${DateTime.now().microsecondsSinceEpoch}',
              type: TileType.bomb,
              row: tile.row,
              col: tile.col,
            );
            _eventController.add(BombEvent(tile.row, tile.col)); // Visual effect
         } else {
            _grid[tile.row][tile.col] = Tile(
              id: 'empty_${tile.row}_${tile.col}_${_random.nextInt(1000)}',
              type: TileType.empty,
              row: tile.row,
              col: tile.col
            );
         }
      }
    }
    notifyListeners();
  }

  Future<void> _triggerBomb(Tile bomb) async {
     List<Tile> tilesToRemove = [];
     for (int r = bomb.row - 1; r <= bomb.row + 1; r++) {
       for (int c = bomb.col - 1; c <= bomb.col + 1; c++) {
         if (r >= 0 && r < rows && c >= 0 && c < cols) {
             tilesToRemove.add(_grid[r][c]);
         }
       }
     }

     int count = 0;
     for (var t in tilesToRemove) {
        if (t.type != TileType.empty) {
          count++;
          _grid[t.row][t.col] = Tile(
             id: 'empty_${t.row}_${t.col}_${_random.nextInt(1000)}',
             type: TileType.empty,
             row: t.row,
             col: t.col
          );
        }
     }

     if (count > 0) {
       int points = count * 10;
       _eventController.add(ScoreEvent(points, bomb.row, bomb.col));
       _eventController.add(DamageEvent(count));
       _eventController.add(BombEvent(bomb.row, bomb.col));
       _eventController.add(ShakeEvent());

       _score += points;
       _monster.currentHp -= count;
       if (_monster.currentHp < 0) _monster.currentHp = 0;
       notifyListeners();
     }
  }

  void _applyGravity() {
    for (int c = 0; c < cols; c++) {
      int writeRow = rows - 1;
      for (int r = rows - 1; r >= 0; r--) {
        if (_grid[r][c].type != TileType.empty) {
          if (writeRow != r) {
            final tile = _grid[r][c];
            _grid[writeRow][c] = tile;
            tile.row = writeRow;

            _grid[r][c] = Tile(
              id: 'empty_${r}_${c}_${_random.nextInt(1000)}',
              type: TileType.empty,
              row: r,
              col: c,
            );
          }
          writeRow--;
        }
      }
    }
  }

  void _refill() {
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
         if (_grid[r][c].type == TileType.empty) {
            _grid[r][c] = _createRandomTile(r, c);
         }
      }
    }
  }
}
