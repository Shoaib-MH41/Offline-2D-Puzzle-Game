import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/tile.dart';
import '../models/monster.dart';
import '../models/rescue_item.dart';
import '../models/level_config.dart';
import '../data/levels_data.dart';

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

class MessageEvent extends GameEvent {
  final String message;
  MessageEvent(this.message);
}

class GameProvider with ChangeNotifier {
  static const int rows = 9;
  static const int cols = 7;

  List<List<Tile>> _grid = [];
  int _score = 0;
  bool _isProcessing = false;
  int _comboCount = 0;

  Monster? _monster;
  List<List<RescueItem>> _rescueGrid = [];
  int _energy = 0;
  bool _isLevelComplete = false;
  bool _isLevelFailed = false;

  int _level = 1;
  GameMode _mode = GameMode.battle;

  int _movesLeft = 0;
  int _maxMoves = 0;

  final _eventController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventController.stream;

  List<List<Tile>> get grid => _grid;
  int get score => _score;
  bool get isProcessing => _isProcessing;
  int get comboCount => _comboCount;
  Monster? get monster => _monster;
  List<List<RescueItem>> get rescueGrid => _rescueGrid;
  int get energy => _energy;
  bool get isLevelComplete => _isLevelComplete;
  bool get isLevelFailed => _isLevelFailed;
  int get level => _level;
  int get movesLeft => _movesLeft;
  int get maxMoves => _maxMoves;
  GameMode get mode => _mode;

  final Random _random = Random();

  GameProvider() {
    _initLevel();
    generateGrid();
  }

  void setLevel(int level) {
    _level = level;
    _initLevel();
    generateGrid();
  }

  void restartLevel() {
    _initLevel();
    generateGrid();
  }

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }

  void _initLevel() {
    final levels = getLevels();
    // Safety check if level > 40
    final config = levels.firstWhere(
        (l) => l.levelNumber == _level,
        orElse: () => levels.last
    );

    _mode = config.mode;
    _maxMoves = config.maxMoves;
    _movesLeft = _maxMoves;
    _score = 0;
    _isLevelComplete = false;
    _isLevelFailed = false;

    if (_mode == GameMode.battle) {
      if (config.monsterConfig != null) {
        // Clone monster to reset state
        _monster = Monster(
          name: config.monsterConfig!.name,
          maxHp: config.monsterConfig!.maxHp,
          currentHp: config.monsterConfig!.maxHp,
          level: config.monsterConfig!.level,
          abilityCooldown: config.monsterConfig!.abilityCooldown,
        );
      } else {
        _monster = Monster(name: "Unknown", maxHp: 100, currentHp: 100, level: _level);
      }
    } else {
      _monster = null;
      if (config.rescueLayout != null) {
          _rescueGrid = [];
          for (int r=0; r<config.rescueLayout!.length; r++) {
              List<RescueItem> row = [];
              for (int c=0; c<config.rescueLayout![r].length; c++) {
                  row.add(RescueItem(
                      id: 'rescue_${r}_$c',
                      type: config.rescueLayout![r][c],
                      row: r,
                      col: c
                  ));
              }
              _rescueGrid.add(row);
          }
      }
      _energy = 0;
    }
  }

  void triggerPin(int r, int c) {
      if (_mode != GameMode.rescue) return;
      if (r < 0 || r >= _rescueGrid.length || c < 0 || c >= _rescueGrid[0].length) return;

      final item = _rescueGrid[r][c];
      if (item.type == RescueType.pin) {
          if (_energy >= 10) {
              _energy -= 10;
              _rescueGrid[r][c] = RescueItem(id: 'empty_pin_${r}_$c', type: RescueType.empty, row: r, col: c);
              notifyListeners();
              _simulateRescuePhysics();
          } else {
              _eventController.add(MessageEvent("Need 10 Energy!"));
          }
      }
  }

  Future<void> _simulateRescuePhysics() async {
    if (_rescueGrid.isEmpty) return;

    bool changed = true;
    while (changed && !_isLevelFailed && !_isLevelComplete) {
      changed = false;
      await Future.delayed(const Duration(milliseconds: 200));

      // Apply Gravity from Bottom to Top
      for (int r = _rescueGrid.length - 2; r >= 0; r--) {
        for (int c = 0; c < _rescueGrid[r].length; c++) {
           final item = _rescueGrid[r][c];
           // Pin, Exit do not fall
           if (item.type != RescueType.empty && item.type != RescueType.pin && item.type != RescueType.exit) {
               // Check below
               final below = _rescueGrid[r+1][c];

               if (below.type == RescueType.empty) {
                   // Move down
                   _rescueGrid[r+1][c] = RescueItem(id: item.id, type: item.type, row: r+1, col: c);
                   _rescueGrid[r][c] = RescueItem(id: 'empty_$r$c', type: RescueType.empty, row: r, col: c);
                   changed = true;
               } else if (item.type == RescueType.hero && below.type == RescueType.exit) {
                   // Win: Hero reaches Exit
                   _rescueGrid[r+1][c] = RescueItem(id: item.id, type: item.type, row: r+1, col: c);
                   _rescueGrid[r][c] = RescueItem(id: 'empty_$r$c', type: RescueType.empty, row: r, col: c);
                   _isLevelComplete = true;
                   notifyListeners();
                   return;
               } else if (_isHazard(item.type) && below.type == RescueType.hero) {
                   // Lose: Hazard falls on Hero
                   _rescueGrid[r+1][c] = RescueItem(id: item.id, type: item.type, row: r+1, col: c); // Visual overwrite
                   _rescueGrid[r][c] = RescueItem(id: 'empty_$r$c', type: RescueType.empty, row: r, col: c);
                   _isLevelFailed = true;
                   notifyListeners();
                   return;
               } else if (item.type == RescueType.hero && _isHazard(below.type)) {
                   // Lose: Hero falls on Hazard
                   _rescueGrid[r+1][c] = RescueItem(id: item.id, type: item.type, row: r+1, col: c); // Visual overwrite
                   _rescueGrid[r][c] = RescueItem(id: 'empty_$r$c', type: RescueType.empty, row: r, col: c);
                   _isLevelFailed = true;
                   notifyListeners();
                   return;
               }
           }
        }
      }
      notifyListeners();
    }
  }

  bool _isHazard(RescueType type) {
    return type == RescueType.lava || type == RescueType.water || type == RescueType.enemy || type == RescueType.hazard;
  }

  void startNextLevel() {
    _level++;
    if (_level > 40) _level = 40; // Cap at 40
    _initLevel();
    generateGrid();
  }

  void generateGrid() {
    // 1. Generate base grid
    _grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        return _createRandomTile(r, c);
      });
    });

    // 2. Place Obstacles based on level
    _placeObstacles();

    // TODO: Ensure no matches on start
    notifyListeners();
  }

  void _placeObstacles() {
     // Level 1-2: No obstacles
     if (_level < 3) return;

     int stoneCount = 0;
     int iceCount = 0;

     // Simple progression
     if (_level >= 3) stoneCount = 2 + (_level ~/ 5);
     if (_level >= 5) iceCount = 2 + (_level ~/ 5);

     // Cap obstacles
     if (stoneCount > 8) stoneCount = 8;
     if (iceCount > 8) iceCount = 8;

     _placeRandomObstacle(TileType.stone, stoneCount);
     _placeRandomObstacle(TileType.ice, iceCount);
  }

  void _placeRandomObstacle(TileType type, int count) {
      int placed = 0;
      int attempts = 0;
      while (placed < count && attempts < 100) {
          int r = _random.nextInt(rows);
          int c = _random.nextInt(cols);

          // Don't overwrite existing obstacles
          if (_grid[r][c].type != TileType.stone &&
              _grid[r][c].type != TileType.ice &&
              _grid[r][c].type != TileType.poison &&
              _grid[r][c].type != TileType.bomb &&
              _grid[r][c].type != TileType.empty) {

              _grid[r][c] = Tile(
                  id: 'obstacle_${type}_${r}_$c',
                  type: type,
                  row: r,
                  col: c,
                  hp: type == TileType.stone ? 2 : 0,
              );
              placed++;
          }
          attempts++;
      }
  }

  Tile _createRandomTile(int row, int col) {
    // Exclude empty, bomb, and obstacles from random generation
    final types = TileType.values.where((t) =>
       t != TileType.empty &&
       t != TileType.bomb &&
       t != TileType.power &&
       t != TileType.key &&
       t != TileType.timedBomb &&
       t != TileType.stone &&
       t != TileType.ice &&
       t != TileType.poison
    ).toList();
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
    if (_movesLeft <= 0) return;

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
    if (tileA.isLocked || tileB.isLocked) return;

    _isProcessing = true;

    // 1. Swap
    _swapTiles(row, col, newRow, newCol);
    notifyListeners();

    // 2. Animate Swap
    await Future.delayed(const Duration(milliseconds: 300));

    // Check for Bomb/Power interaction
    bool isSpecialInteraction = tileA.isBomb || tileB.isBomb || tileA.isPower || tileB.isPower;
    bool validMove = false;

    if (isSpecialInteraction) {
       validMove = true;

       if (_grid[tileA.row][tileA.col].isBomb) {
         await _triggerBomb(tileA);
       } else if (_grid[tileA.row][tileA.col].isPower) {
         await _triggerPower(tileA);
       }

       final t1 = _grid[newRow][newCol];
       if (t1.isBomb) {
         await _triggerBomb(t1);
       } else if (t1.isPower) {
         await _triggerPower(t1);
       }

       final t2 = _grid[row][col];
       if (t2.isBomb) {
         await _triggerBomb(t2);
       } else if (t2.isPower) {
         await _triggerPower(t2);
       }

       await _processBoard();
    } else {
      // Normal Match Check
      final matches = _checkMatches();

      if (matches.isNotEmpty) {
         validMove = true;
         await _processBoard();
      } else {
        // Revert
        _swapTiles(row, col, newRow, newCol);
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300)); // Animate back
      }
    }

    if (validMove) {
      _movesLeft--;
      _processTurnEnd();
      _unlockAllTiles(); // Clear previous locks

      // Monster Turn (Only in Battle Mode)
      if (_mode == GameMode.battle && _monster != null) {
          _monster!.turnsCounter++;
          if (_monster!.turnsCounter >= _monster!.abilityCooldown && !_monster!.isDead) {
             _monster!.turnsCounter = 0;
             await _monsterAction();
          }
      }
    }

    _isProcessing = false;
    notifyListeners(); // Ensure UI updates (e.g. moves count)
  }

  void _unlockAllTiles() {
    for (var r in _grid) {
      for (var t in r) {
        t.isLocked = false;
      }
    }
  }

  void _unlockLockedTiles(int count) {
      int unlocked = 0;
      for (var r in _grid) {
          for (var t in r) {
              if (t.isLocked && unlocked < count) {
                  t.isLocked = false;
                  unlocked++;
              }
          }
      }
      if (unlocked > 0) {
           _eventController.add(MessageEvent("Unlocked $unlocked Tiles!"));
      }
  }

  void _processTurnEnd() {
      // 1. Poison Damage
      int poisonCount = 0;
      for (var r in _grid) {
          for (var t in r) {
              if (t.type == TileType.poison) {
                poisonCount++;
              } else if (t.type == TileType.timedBomb) {
                  t.turnsLeft--;
                  if (t.turnsLeft <= 0) {
                       _movesLeft -= 5;
                       if (_movesLeft < 0) {
                         _movesLeft = 0;
                       }
                       _eventController.add(MessageEvent("Bomb Exploded! -5 Moves"));
                       _grid[t.row][t.col] = Tile(
                           id: 'exploded_${t.id}',
                           type: TileType.empty,
                           row: t.row,
                           col: t.col
                       );
                       _eventController.add(ShakeEvent());
                  }
              }
          }
      }
      if (poisonCount > 0) {
          int penalty = poisonCount * 50;
          _score -= penalty;
          if (_score < 0) {
            _score = 0;
          }
          _eventController.add(MessageEvent("Poison Damage: -$penalty"));
      }
  }

  Future<void> _monsterAction() async {
    if (_monster == null) return;
    // 3 Abilities: Heal, Lock Row, Poison
    // Pick random
    int action = _random.nextInt(3);

    if (action == 0) {
      // Heal
      int heal = 50 + (_level * 10);
      _monster!.currentHp += heal;
      if (_monster!.currentHp > _monster!.maxHp) _monster!.currentHp = _monster!.maxHp;
      _eventController.add(MessageEvent("Monster Healed $heal HP!"));
    } else if (action == 1) {
      // Lock Random Row
      int r = _random.nextInt(rows);
      for (int c = 0; c < cols; c++) {
         if (_grid[r][c].type != TileType.empty) {
           _grid[r][c].isLocked = true;
         }
      }
      _eventController.add(MessageEvent("Monster Locked Row ${r+1}!"));
    } else {
      // Add Poison Tile
      // Replace a random normal tile
      int attempts = 0;
      while (attempts < 20) {
        int r = _random.nextInt(rows);
        int c = _random.nextInt(cols);
        final t = _grid[r][c];
        if (t.type != TileType.empty && t.type != TileType.bomb &&
            t.type != TileType.stone && t.type != TileType.ice && t.type != TileType.poison) {
            _grid[r][c] = Tile(
              id: 'poison_${DateTime.now().microsecondsSinceEpoch}',
              type: TileType.poison,
              row: r,
              col: c
            );
            break;
        }
        attempts++;
      }
      _eventController.add(MessageEvent("Monster Poisoned a Tile!"));
    }
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500)); // Pause for player to see
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

    bool canMatch(TileType t) {
      return t != TileType.empty &&
             t != TileType.bomb &&
             t != TileType.power &&
             t != TileType.timedBomb &&
             t != TileType.key &&
             t != TileType.stone &&
             t != TileType.ice &&
             t != TileType.poison;
    }

    // Horizontal
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols - 2; c++) {
        final t1 = _grid[r][c];
        final t2 = _grid[r][c+1];
        final t3 = _grid[r][c+2];
        if (canMatch(t1.type) &&
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
        if (canMatch(t1.type) &&
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
    Set<Tile> obstaclesToDamage = {};

    for (var cluster in matchClusters) {
      if (cluster.isEmpty) continue;

      int multiplier = _comboCount > 0 ? _comboCount : 1;
      int points = cluster.length * 10 * multiplier;
      int damage = cluster.length * multiplier;

      final center = cluster[cluster.length ~/ 2];
      _eventController.add(ScoreEvent(points, center.row, center.col));
      _eventController.add(DamageEvent(damage));

      _score += points;

      if (_mode == GameMode.battle && _monster != null) {
          _monster!.currentHp -= damage;
          if (_monster!.currentHp < 0) _monster!.currentHp = 0;
      } else if (_mode == GameMode.rescue) {
          _energy += damage;
      }

      // Key Unlock Logic
      if (center.type == TileType.key) {
           _unlockLockedTiles(3);
      }

      // Determine special creation
      TileType? specialType;
      Tile? specialTarget;

      if (cluster.length >= 5) {
         specialType = TileType.bomb;
         specialTarget = center;
      } else if (cluster.length == 4) {
         specialType = TileType.power;
         specialTarget = center;
      }

      // Check adjacent obstacles
      for (var tile in cluster) {
         for (var dir in [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
            int nr = tile.row + dir[0];
            int nc = tile.col + dir[1];
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
               final neighbor = _grid[nr][nc];
               if (neighbor.type == TileType.stone || neighbor.type == TileType.ice || neighbor.type == TileType.poison) {
                  obstaclesToDamage.add(neighbor);
               }
            }
         }
      }

      for (var tile in cluster) {
         if (specialTarget != null && tile == specialTarget) {
            _grid[tile.row][tile.col] = Tile(
              id: '${specialType}_${DateTime.now().microsecondsSinceEpoch}',
              type: specialType!,
              row: tile.row,
              col: tile.col,
            );
            if (specialType == TileType.bomb) {
               _eventController.add(BombEvent(tile.row, tile.col));
            }
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

    // Process Obstacle Damage
    for (var obs in obstaclesToDamage) {
       // Re-fetch in case it was modified? No, objects are ref.
       // But grid position matters.

       if (obs.type == TileType.stone) {
          obs.hp--;
          if (obs.hp <= 0) {
             _grid[obs.row][obs.col] = Tile(id: 'broken_${obs.id}', type: TileType.empty, row: obs.row, col: obs.col);
             _eventController.add(ScoreEvent(20, obs.row, obs.col));
          }
       } else if (obs.type == TileType.ice || obs.type == TileType.poison) {
           _grid[obs.row][obs.col] = Tile(id: 'broken_${obs.id}', type: TileType.empty, row: obs.row, col: obs.col);
           _eventController.add(ScoreEvent(30, obs.row, obs.col));
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
     await _clearTiles(tilesToRemove, bomb.row, bomb.col);
  }

  Future<void> _triggerPower(Tile power) async {
     List<Tile> tilesToRemove = [];
     for (int c = 0; c < cols; c++) {
        tilesToRemove.add(_grid[power.row][c]);
     }
     for (int r = 0; r < rows; r++) {
        if (r != power.row) {
            tilesToRemove.add(_grid[r][power.col]);
        }
     }
     await _clearTiles(tilesToRemove, power.row, power.col);
  }

  Future<void> _clearTiles(List<Tile> tiles, int originRow, int originCol) async {
     int count = 0;
     for (var t in tiles) {
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
       _eventController.add(ScoreEvent(points, originRow, originCol));
       _eventController.add(DamageEvent(count));
       _eventController.add(ShakeEvent());

       _score += points;

       if (_mode == GameMode.battle && _monster != null) {
           _monster!.currentHp -= count;
           if (_monster!.currentHp < 0) _monster!.currentHp = 0;
       }
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
