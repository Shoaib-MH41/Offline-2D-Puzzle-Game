import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/tile.dart';
import '../models/monster.dart';

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

class GameProvider with ChangeNotifier {
  static const int rows = 9;
  static const int cols = 7;

  List<List<Tile>> _grid = [];
  int _score = 0;
  bool _isProcessing = false;

  late Monster _monster;
  int _level = 1;

  final _eventController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventController.stream;

  List<List<Tile>> get grid => _grid;
  int get score => _score;
  bool get isProcessing => _isProcessing;
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
    // Keep score and level state?
    // If we call generateGrid manually (refresh), should we reset monster?
    // The current UI calls generateGrid on refresh button.
    // Let's assume refresh button resets the level state for now or just the grid.
    // Ideally, "Restart Level" resets grid and monster.

    _grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        return _createRandomTile(r, c);
      });
    });
    notifyListeners();
  }

  Tile _createRandomTile(int row, int col) {
    final types = TileType.values.where((t) => t != TileType.empty).toList();
    final type = types[_random.nextInt(types.length)];
    return Tile(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(100000)}',
      type: type,
      row: row,
      col: col,
    );
  }

  Future<void> handleTap(int row, int col) async {
    if (_isProcessing) return;
    if (row < 0 || row >= rows || col < 0 || col >= cols) return;

    final tile = _grid[row][col];
    if (tile.type == TileType.empty) return;

    List<Tile> tilesToRemove = [];
    bool createdBomb = false;

    if (tile.isBomb) {
      tilesToRemove = _getBombRadius(row, col);
    } else {
      tilesToRemove = _findConnected(row, col, tile.type);
    }

    if (tilesToRemove.length >= 2 || tile.isBomb) {
        _isProcessing = true;
        notifyListeners();

        if (!tile.isBomb && tilesToRemove.length >= 5) {
          createdBomb = true;
        }

        // Emit events
        int damage = tilesToRemove.length;
        int points = damage * 10;

        _eventController.add(ScoreEvent(points, row, col));
        _eventController.add(DamageEvent(damage));
        if (tile.isBomb) {
           _eventController.add(BombEvent(row, col));
        }

        // Remove tiles
        _removeTiles(tilesToRemove);

        if (createdBomb) {
           // Create bomb at tapped location
           _grid[row][col] = Tile(
             id: 'bomb_${DateTime.now().microsecondsSinceEpoch}',
             type: tile.type,
             row: row,
             col: col,
             isBomb: true,
           );
        }

        _score += points;

        // Apply damage to monster
        _monster.currentHp -= damage;
        if (_monster.currentHp < 0) _monster.currentHp = 0;

        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 350));

        // Apply gravity
        _applyGravity();
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 350));

        // Refill
        _refill();
        notifyListeners();

        _isProcessing = false;
    }
  }

  List<Tile> _getBombRadius(int row, int col) {
    List<Tile> result = [];
    for (int r = row - 1; r <= row + 1; r++) {
      for (int c = col - 1; c <= col + 1; c++) {
        if (r >= 0 && r < rows && c >= 0 && c < cols) {
          if (_grid[r][c].type != TileType.empty) {
             result.add(_grid[r][c]);
          }
        }
      }
    }
    return result;
  }

  List<Tile> _findConnected(int startRow, int startCol, TileType type) {
    List<Tile> result = [];
    Set<String> visited = {};
    List<Tile> queue = [_grid[startRow][startCol]];
    visited.add('$startRow,$startCol');

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);

      final directions = [
        [-1, 0], [1, 0], [0, -1], [0, 1]
      ];

      for (var dir in directions) {
        final newRow = current.row + dir[0];
        final newCol = current.col + dir[1];

        if (newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols) {
           final neighbor = _grid[newRow][newCol];
           // Check if neighbor is of same type and not visited
           if (!visited.contains('$newRow,$newCol') && neighbor.type == type) {
             visited.add('$newRow,$newCol');
             queue.add(neighbor);
           }
        }
      }
    }
    return result;
  }

  void _removeTiles(List<Tile> tiles) {
    for (var tile in tiles) {
       _grid[tile.row][tile.col] = Tile(
         id: 'empty_${tile.row}_${tile.col}_${_random.nextInt(1000)}',
         type: TileType.empty,
         row: tile.row,
         col: tile.col
       );
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
