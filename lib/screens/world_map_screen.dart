import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  int _highestLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final storage = context.read<StorageService>();
    final level = await storage.getHighestLevel();
    setState(() {
      _highestLevel = level;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            final worldIndex = (level - 1) ~/ 10;

            Widget? header;
            if ((level - 1) % 10 == 0) {
               String worldName = "World ${worldIndex + 1}";
               if (worldIndex == 0) {
                 worldName = "Goblin Forest";
               } else if (worldIndex == 1) {
                 worldName = "Fire Dungeon";
               } else if (worldIndex == 2) {
                 worldName = "Snake Temple";
               } else {
                 worldName = "Dark Castle";
               }

               header = Padding(
                 padding: const EdgeInsets.symmetric(vertical: 16.0),
                 child: Text(worldName, style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
               );
            }

            // Determine if rescue (Logic from levels_data: levels 2, 7, 12, 17...)
            bool isRescue = (level % 5 == 2);
            bool isBoss = (level % 10 == 0);

            final card = Card(
              color: isLocked ? Colors.grey[700] : Colors.amber[100],
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLocked ? Colors.grey : (isBoss ? Colors.red : (isRescue ? Colors.blue : Colors.orange)),
                  child: Icon(
                    isLocked ? Icons.lock : (isBoss ? Icons.whatshot : (isRescue ? Icons.person : Icons.colorize)),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  isLocked ? "Locked" : (isBoss ? "BOSS BATTLE" : "Level $level"),
                  style: TextStyle(color: isLocked ? Colors.white54 : Colors.black, fontWeight: isLocked ? FontWeight.normal : FontWeight.bold)
                ),
                subtitle: isLocked ? null : Text(isRescue ? "Rescue Mode" : "Battle Mode"),
                trailing: isLocked ? const Icon(Icons.lock, color: Colors.white54) : const Icon(Icons.play_arrow, color: Colors.orange),
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
