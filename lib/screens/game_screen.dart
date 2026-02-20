import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../services/storage_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().generateGrid();
    });
  }

  @override
  Widget build(BuildContext context) {
    final score = context.select<GameProvider, int>((g) => g.score);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
         if (didPop) {
           final storage = context.read<StorageService>();
           await storage.saveHighScore(score);
         }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Score: $score'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<GameProvider>().generateGrid();
              },
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                 final storage = context.read<StorageService>();
                 await storage.saveHighScore(score);
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Score Saved!')),
                   );
                 }
              },
            )
          ],
        ),
        body: Container(
          color: Colors.grey[200],
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
                 aspectRatio: 7 / 9,
                 child: const BoardWidget(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
