import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/rescue_item.dart';

class RescueWidget extends StatelessWidget {
  const RescueWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final grid = gameProvider.rescueGrid;

    if (grid.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
          ),
          child: const Text(
            "OBJECTIVE: Rescue the Hero! (Pin Cost: 10 Energy)",
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: Border.all(color: Colors.amber, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: grid.asMap().entries.map((entry) {
                  int r = entry.key;
                  List<RescueItem> row = entry.value;
                  return Expanded(
                    child: Row(
                      children: row.asMap().entries.map((e) {
                        int c = e.key;
                        RescueItem item = e.value;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => gameProvider.triggerPin(r, c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: _getColor(item.type),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.black26),
                                boxShadow: item.type == RescueType.pin ? [
                                  const BoxShadow(color: Colors.black45, offset: Offset(1,1), blurRadius: 2)
                                ] : null,
                              ),
                              child: Center(
                                child: _getIcon(item.type),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColor(RescueType type) {
    switch (type) {
      case RescueType.hero: return Colors.blueAccent;
      case RescueType.enemy: return Colors.red[800]!;
      case RescueType.water: return Colors.blue[300]!;
      case RescueType.lava: return Colors.orange[800]!;
      case RescueType.stone: return Colors.grey[700]!;
      case RescueType.gold: return Colors.amber;
      case RescueType.pin: return Colors.amber[700]!;
      case RescueType.exit: return Colors.green[700]!;
      case RescueType.empty: return Colors.black12;
      case RescueType.sand: return const Color(0xFFE1C699); // Sand color
      case RescueType.hazard: return Colors.deepOrangeAccent;
    }
  }

  Widget _getIcon(RescueType type) {
    switch (type) {
      case RescueType.hero: return const Icon(Icons.person, color: Colors.white, size: 24);
      case RescueType.enemy: return const Icon(Icons.bug_report, color: Colors.black, size: 24);
      case RescueType.water: return const Icon(Icons.water_drop, color: Colors.blueAccent, size: 20);
      case RescueType.lava: return const Icon(Icons.local_fire_department, color: Colors.yellow, size: 20);
      case RescueType.stone: return const Icon(Icons.landscape, color: Colors.black54, size: 20);
      case RescueType.gold: return const Icon(Icons.monetization_on, color: Colors.white, size: 20);
      case RescueType.pin: return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock, color: Colors.black, size: 16),
          Text("10", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      );
      case RescueType.exit: return const Icon(Icons.door_back_door, color: Colors.white, size: 24);
      case RescueType.empty: return const SizedBox.shrink();
      case RescueType.sand: return const Icon(Icons.grain, color: Colors.orange, size: 16);
      case RescueType.hazard: return const Icon(Icons.warning, color: Colors.yellowAccent, size: 20);
    }
  }
}
