import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'services/storage_service.dart';
import 'services/level_service.dart';
import 'screens/main_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final levelService = LevelService();
  await levelService.loadLevels();

  runApp(PuzzleGameApp(levelService: levelService));
}

class PuzzleGameApp extends StatelessWidget {
  final LevelService levelService;

  const PuzzleGameApp({super.key, required this.levelService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LevelService>.value(value: levelService),
        ChangeNotifierProvider(create: (_) => GameProvider(levelService)),
        Provider(create: (_) => StorageService()),
      ],
      child: MaterialApp(
        title: 'Offline Puzzle Game',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MainMenu(),
      ),
    );
  }
}
