import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/models/tile.dart';
import 'package:puzzle_game/models/level_config.dart';
import 'package:puzzle_game/providers/game_provider.dart';
import 'package:puzzle_game/services/level_service.dart';

class MockLevelService extends LevelService {
  @override
  LevelConfig getLevel(int level) {
    return LevelConfig(
      levelNumber: level,
      mode: GameMode.battle,
      maxMoves: 20,
      worldIndex: 0,
      targetScore: 1000,
    );
  }
}

void main() {
  group('GameProvider Tests', () {
    late GameProvider provider;

    setUp(() {
      provider = GameProvider(MockLevelService());

      // Fill grid with checkerboard pattern to ensure no matches
      // Need to manually overwrite grid AFTER initialization
      // because constructor calls generateGrid which randomizes.

      // We can't access private _grid directly, but getter returns reference to List<List<Tile>>.
      // So we can modify the contents of the lists.
      // But we can't replace the list itself.

      // However, generateGrid replaces _grid.
      // So we need to modify the grid contents.

      // Let's create a custom grid setter helper or just loop.
      for (int r = 0; r < GameProvider.rows; r++) {
        for (int c = 0; c < GameProvider.cols; c++) {
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
      final t1 = provider.grid[0][0];
      final t2 = provider.grid[0][1];
      final id1 = t1.id;
      final id2 = t2.id;

      await provider.handleSwap(0, 0, Direction.right);

      // Wait for async
      // But handleSwap is async. Await should be enough if using fake async or real delay.
      // Since handleSwap uses Future.delayed, we might need pump or just wait.
      // But unit tests run in real time unless using fakeAsync.
      // Simple await might work if delays are mocked or we wait long enough?
      // No, existing code uses `await Future.delayed`.
      // Unit test environment usually skips delays or runs fast?
      // No, `flutter_test` waits.
      // So we should just verify state after await.

      expect(provider.grid[0][0].id, id1);
      expect(provider.grid[0][1].id, id2);
    });

    test('handleSwap processes match', () async {
      // Setup row 0: Sword(0), Shield(1), Sword(2), Shield(3)
      // 0,0 is Sword.
      // 0,1 is Shield. Set to Sword.
      provider.grid[0][1] = Tile(id: 's2', type: TileType.sword, row: 0, col: 1);
      // 0,2 is Sword. Set to Shield.
      provider.grid[0][2] = Tile(id: 'sh1', type: TileType.shield, row: 0, col: 2);
      // 0,3 is Shield. Set to Sword.
      provider.grid[0][3] = Tile(id: 's3', type: TileType.sword, row: 0, col: 3);

      // Now: Sword, Sword, Shield, Sword.
      // Swap 0,2 (Shield) with 0,3 (Sword) -> Sword, Sword, Sword, Shield.
      // Match 3 at 0,0..0,2.

      await provider.handleSwap(0, 2, Direction.right);

      // Need to wait for processing loop?
      // handleSwap awaits _processBoard which loops.
      // So awaiting handleSwap should suffice.

      expect(provider.score, greaterThan(0));
    });
  });
}
