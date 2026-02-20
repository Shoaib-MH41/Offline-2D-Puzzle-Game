import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/models/tile.dart';
import 'package:puzzle_game/providers/game_provider.dart';

void main() {
  group('GameProvider Tests', () {
    late GameProvider provider;

    setUp(() {
      provider = GameProvider();
    });

    test('generateGrid creates a 9x7 grid with non-empty tiles', () {
      expect(provider.grid.length, 9);
      expect(provider.grid[0].length, 7);

      for (var row in provider.grid) {
        for (var tile in row) {
          expect(tile.type, isNot(TileType.empty));
        }
      }
    });

    test('handleTap with match >= 2 removes tiles and updates score', () async {
      // Set bottom two tiles of column 0 to RED
      // Grid is 9 rows (0-8). 8 is bottom.
      provider.grid[8][0] = Tile(id: 'r1', type: TileType.red, row: 8, col: 0);
      provider.grid[7][0] = Tile(id: 'r2', type: TileType.red, row: 7, col: 0);

      // Ensure neighbor (8,1) and (7,1) and (6,0) are different
      provider.grid[8][1] = Tile(id: 'b1', type: TileType.blue, row: 8, col: 1);
      provider.grid[7][1] = Tile(id: 'b2', type: TileType.blue, row: 7, col: 1);
      provider.grid[6][0] = Tile(id: 'g1', type: TileType.green, row: 6, col: 0);

      // Initial score
      expect(provider.score, 0);

      // Tap on (8, 0)
      await provider.handleTap(8, 0);

      // Score should increase (2 tiles * 10 = 20)
      expect(provider.score, 20);

      // (8,0) and (7,0) were removed.
      // (6,0) which was Green should fall down to fill the gap.
      // 2 tiles removed. Gap created at 8,0 and 7,0.
      // Gravity pulls 6,0 down to 8,0 (since 2 slots cleared below it).

      // Check 8,0 is now Green (the one that fell) OR a new random tile if refill logic applies?
      // Wait. Logic:
      // Remove 8,0 and 7,0.
      // Apply Gravity:
      // 6,0 moves to 8,0. (Green)
      // 5,0 moves to 7,0.
      // ...
      // Refill fills top.

      // So 8,0 should be the Green tile (id: g1).
      expect(provider.grid[8][0].id, 'g1');
      expect(provider.grid[8][0].type, TileType.green);
    });

    test('handleTap with single tile does nothing', () async {
      // Set 8,0 to RED. Neighbors to BLUE.
      provider.grid[8][0] = Tile(id: 'r1', type: TileType.red, row: 8, col: 0);
      provider.grid[8][1] = Tile(id: 'b1', type: TileType.blue, row: 8, col: 1);
      provider.grid[7][0] = Tile(id: 'b2', type: TileType.blue, row: 7, col: 0);

      final originalId = provider.grid[8][0].id;

      await provider.handleTap(8, 0);

      expect(provider.score, 0);
      expect(provider.grid[8][0].id, originalId);
      expect(provider.grid[8][0].type, TileType.red);
    });
  });
}
