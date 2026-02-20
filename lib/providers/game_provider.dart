import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/tile.dart';

class GameProvider with ChangeNotifier {
  static const int rows = 9;
  static const int cols = 7;

  List<List<Tile>> _grid = [];
  int _score = 0;
  bool _isProcessing = false;

  List<List<Tile>> get grid => _grid;
  int get score => _score;
  bool get isProcessing => _isProcessing;

  final Random _random = Random();

  GameProvider() {
    generateGrid();
  }

  void generateGrid() {
    _score = 0;
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

    final connected = _findConnected(row, col, tile.type);
    if (connected.length >= 2) {
        _isProcessing = true;
        notifyListeners();

        // Remove tiles
        _removeTiles(connected);
        _score += connected.length * 10;
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 200));

        // Apply gravity
        _applyGravity();
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 200));

        // Refill
        _refill();
        notifyListeners();

        _isProcessing = false;
    }
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
