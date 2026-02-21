import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/models/tile.dart';
import 'package:puzzle_game/providers/game_provider.dart';

void main() {
  group('GameProvider Tests', () {
    late GameProvider provider;

    setUp(() {
      provider = GameProvider();
      // Fill grid with checkerboard pattern to ensure no matches
      for (int r = 0; r < GameProvider.rows; r++) {
        for (int c = 0; c < GameProvider.cols; c++) {
          // Alternating Sword and Shield
          final type = (r + c) % 2 == 0 ? TileType.sword : TileType.shield;
          provider.grid[r][c] = Tile(
            id: 'init_${r}_$c',
            type: type,
            row: r,
            col: c
          );
        }
      }
    });

    test('generateGrid creates a 9x7 grid', () {
      expect(provider.grid.length, 9);
      expect(provider.grid[0].length, 7);
    });

    test('handleSwap reverts if no match', () async {
      // 0,0 is Sword (0+0 even). 0,1 is Shield (0+1 odd).
      // 0,2 is Sword.
      // Swap 0,0 and 0,1.
      // 0,0 becomes Shield. 0,1 becomes Sword.
      // Row 0: Shield, Sword, Sword. No match.
      // Col 0: Shield, Shield(1,0), Sword(2,0)...
      // 1,0 is Shield (1+0 odd).
      // So 0,0 (Shield) matches 1,0 (Shield). Need to check 2,0.
      // 2,0 is Sword.
      // So no match.

      final id1 = provider.grid[0][0].id;
      final id2 = provider.grid[0][1].id;

      await provider.handleSwap(0, 0, Direction.right);

      // Should revert
      expect(provider.grid[0][0].id, id1);
      expect(provider.grid[0][1].id, id2);
    });

    test('handleSwap matches 3 and processes', () async {
      // Setup row 0 to be Sword, Sword, Shield, Sword
      // 0,0: Sword (default)
      // 0,1: Shield (default) -> Change to Sword
      provider.grid[0][1] = Tile(id: 's2', type: TileType.sword, row: 0, col: 1);
      // 0,2: Sword (default) -> Change to Shield
      provider.grid[0][2] = Tile(id: 'sh1', type: TileType.shield, row: 0, col: 2);
      // 0,3: Shield (default) -> Change to Sword
      provider.grid[0][3] = Tile(id: 's3', type: TileType.sword, row: 0, col: 3);

      // Now: Sword, Sword, Shield, Sword.
      // Swap 0,2 and 0,3 -> Sword, Sword, Sword, Shield.
      // Match 3 at 0,0..0,2.

      await provider.handleSwap(0, 2, Direction.right);

      expect(provider.score, greaterThan(0));
    });
  });
}
