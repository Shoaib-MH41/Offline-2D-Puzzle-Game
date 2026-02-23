import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/level_service.dart';
import '../providers/game_provider.dart';
import '../models/level_config.dart';
import 'game_screen.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  int _highestLevel = 1;
  Map<int, int> _stars = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final storage = context.read<StorageService>();
    final level = await storage.getHighestLevel();
    Map<int, int> stars = {};
    for(int i=1; i<=level; i++) {
       stars[i] = await storage.getLevelStars(i);
    }

    setState(() {
      _highestLevel = level;
      _stars = stars;
    });
  }

  @override
  Widget build(BuildContext context) {
    final levelService = context.read<LevelService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("World Map", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.brown[800],
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 40,
          itemBuilder: (context, index) {
            final level = index + 1;
            final isLocked = level > _highestLevel;
            final config = levelService.getLevel(level);
            final worldIndex = config.worldIndex;

            Widget? header;
            if ((level - 1) % 10 == 0) {
               String worldName = "World ${worldIndex + 1}";
               if (worldIndex == 0) {
                 worldName = "Goblin Forest 🌲";
               } else if (worldIndex == 1) {
                 worldName = "Fire Dungeon 🔥";
               } else if (worldIndex == 2) {
                 worldName = "Snake Temple 🐍";
               } else {
                 worldName = "Dark Castle 🏰";
               }

               header = Padding(
                 padding: const EdgeInsets.symmetric(vertical: 16.0),
                 child: Text(worldName, style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
               );
            }

            bool isBoss = (level % 10 == 0);
            int starCount = _stars[level] ?? 0;

            final card = Card(
              color: isLocked ? Colors.grey[700] : Colors.amber[100],
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: isLocked ? Colors.grey : (isBoss ? Colors.red : (config.mode == GameMode.rescue ? Colors.blue : Colors.orange)),
                      child: Text(
                        isLocked ? "🔒" : (isBoss ? "👹" : (config.mode == GameMode.rescue ? "🦸" : "⚔️")),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    if (level == _highestLevel && !isLocked)
                       Transform.translate(offset: const Offset(12, 12), child: const Text("⭐", style: TextStyle(fontSize: 16))), // Hero marker?
                  ],
                ),
                title: Text(
                  isLocked ? "Locked" : (isBoss ? "BOSS BATTLE" : "Level $level"),
                  style: TextStyle(color: isLocked ? Colors.white54 : Colors.black, fontWeight: isLocked ? FontWeight.normal : FontWeight.bold)
                ),
                subtitle: isLocked ? null : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(config.mode == GameMode.rescue ? "Rescue Mode" : "Battle Mode"),
                    if (starCount > 0)
                      Row(
                        children: List.generate(3, (i) => Text(
                           i < starCount ? "⭐" : "⚫",
                           style: const TextStyle(fontSize: 14),
                        )),
                      )
                  ],
                ),
                trailing: isLocked
                   ? const Text("🔒", style: TextStyle(fontSize: 24, color: Colors.white54))
                   : (level == _highestLevel ? const Text("📍", style: TextStyle(fontSize: 24, color: Colors.redAccent)) : const Text("✅", style: TextStyle(fontSize: 24, color: Colors.green))),
                onTap: isLocked ? null : () => _playLevel(level),
              ),
            );

            if (header != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [header, card],
              );
            }
            return card;
          },
        ),
      ),
    );
  }

  void _playLevel(int level) {
    context.read<GameProvider>().setLevel(level);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GameScreen()),
    ).then((_) => _loadProgress());
  }
}
