import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle_game/providers/game_provider.dart';
import 'package:puzzle_game/services/storage_service.dart';
import 'package:puzzle_game/services/level_service.dart';
import 'package:puzzle_game/models/level_config.dart';
import 'package:puzzle_game/screens/game_screen.dart';
import 'package:puzzle_game/widgets/board_widget.dart';
import 'package:puzzle_game/widgets/tile_widget.dart';

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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GameScreen renders BoardWidget and Score', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LevelService>(create: (_) => MockLevelService()),
          ChangeNotifierProvider(create: (_) => GameProvider(MockLevelService())),
          Provider(create: (_) => StorageService()),
        ],
        child: const MaterialApp(
          home: GameScreen(),
        ),
      ),
    );

    // Verify Score UI (Score label and value are separate now)
    expect(find.text('Score'), findsOneWidget);
    // Value '0' might appear multiple times (Score, Energy hidden, maybe somewhere else)
    // But at least it should be there.
    expect(find.text('0'), findsAtLeastNWidgets(1));

    // Verify BoardWidget
    expect(find.byType(BoardWidget), findsOneWidget);

    // Verify tiles are rendered
    await tester.pumpAndSettle();

    // Check for TileWidgets
    expect(find.byType(TileWidget), findsWidgets);

    // Check number of tiles. Should be 63 (9*7).
    expect(find.byType(TileWidget), findsNWidgets(63));
  });
}
