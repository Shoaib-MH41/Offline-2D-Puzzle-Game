import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle_game/providers/game_provider.dart';
import 'package:puzzle_game/services/storage_service.dart';
import 'package:puzzle_game/screens/game_screen.dart';
import 'package:puzzle_game/widgets/board_widget.dart';
import 'package:puzzle_game/widgets/tile_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GameScreen renders BoardWidget and Score', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GameProvider()),
          Provider(create: (_) => StorageService()),
        ],
        child: const MaterialApp(
          home: GameScreen(),
        ),
      ),
    );

    // Verify AppBar title
    expect(find.text('Score: 0'), findsOneWidget);

    // Verify BoardWidget
    expect(find.byType(BoardWidget), findsOneWidget);

    // Verify tiles are rendered
    await tester.pumpAndSettle();

    // Check for TileWidgets
    // Since we didn't export TileWidget in a library, we import it directly.
    expect(find.byType(TileWidget), findsWidgets);

    // Check number of tiles. Should be 63.
    expect(find.byType(TileWidget), findsNWidgets(63));

    // Icons.refresh and Icons.save were removed in redesign
    // expect(find.byIcon(Icons.refresh), findsOneWidget);
    // expect(find.byIcon(Icons.save), findsOneWidget);
  });
}
