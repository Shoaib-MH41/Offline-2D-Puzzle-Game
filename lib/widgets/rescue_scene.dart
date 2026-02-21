import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/rescue_item.dart';

class RescueScene extends StatelessWidget {
  const RescueScene({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final rescueGrid = gameProvider.rescueGrid;

    if (rescueGrid.isEmpty) {
      return const Center(child: Text("No Rescue Level Loaded"));
    }

    int rows = rescueGrid.length;
    int cols = rescueGrid[0].length;

    return Container(
      color: Colors.brown[900], // Dark background for rescue scene
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Header: Energy / Objective
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.yellowAccent),
                    const SizedBox(width: 8),
                    Text(
                      "Energy: ${gameProvider.energy}",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  "Rescue the Hero!",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
                ),
              ],
            ),
          ),

          // The Rescue Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate cell size to fit
                double cellWidth = constraints.maxWidth / cols;
                double cellHeight = constraints.maxHeight / rows;
                double size = cellWidth < cellHeight ? cellWidth : cellHeight;

                // Center the grid
                double totalWidth = size * cols;
                double totalHeight = size * rows;

                return Center(
                  child: SizedBox(
                    width: totalWidth,
                    height: totalHeight,
                    child: Stack(
                      children: [
                        // Background Grid
                        for (int r = 0; r < rows; r++)
                          for (int c = 0; c < cols; c++)
                            Positioned(
                              top: r * size,
                              left: c * size,
                              width: size,
                              height: size,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white10),
                                  color: Colors.black26,
                                ),
                              ),
                            ),

                        // Items
                        for (int r = 0; r < rows; r++)
                          for (int c = 0; c < cols; c++)
                            _buildRescueItem(context, rescueGrid[r][c], size, gameProvider),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRescueItem(BuildContext context, RescueItem item, double size, GameProvider provider) {
    if (item.type == RescueType.empty) return const SizedBox.shrink();

    return AnimatedPositioned(
      key: ValueKey(item.id),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: item.row * size,
      left: item.col * size,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          if (item.type == RescueType.pin) {
             provider.triggerPin(item.row, item.col);
          }
        },
        child: Container(
          margin: const EdgeInsets.all(2), // Slight gap
          decoration: _getDecoration(item.type),
          child: Center(
            child: _getIcon(item.type, size),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getDecoration(RescueType type) {
    switch (type) {
      case RescueType.pin:
        return BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[600]!, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 2)],
        );
      case RescueType.stone:
        return BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(4));
      case RescueType.sand:
        return BoxDecoration(color: Colors.amber[200], borderRadius: BorderRadius.circular(4));
      case RescueType.gold:
        return BoxDecoration(color: Colors.amber[600], shape: BoxShape.circle);
      case RescueType.water:
        return BoxDecoration(color: Colors.blue.withValues(alpha: 0.6));
      case RescueType.lava:
        return BoxDecoration(color: Colors.orange.withValues(alpha: 0.8));
      case RescueType.exit:
        return BoxDecoration(
             color: Colors.green.withValues(alpha: 0.3),
             border: Border.all(color: Colors.greenAccent, width: 2),
             borderRadius: BorderRadius.circular(8)
        );
      default:
        return const BoxDecoration();
    }
  }

  Widget _getIcon(RescueType type, double size) {
    double iconSize = size * 0.7;
    switch (type) {
      case RescueType.hero:
        return Icon(Icons.person, color: Colors.blueAccent, size: iconSize);
      case RescueType.enemy:
        return Icon(Icons.adb, color: Colors.redAccent, size: iconSize);
      case RescueType.pin:
        return Icon(Icons.vpn_key, color: Colors.amber[800], size: iconSize); // Pin handle
      case RescueType.exit:
        return Icon(Icons.door_back_door, color: Colors.greenAccent, size: iconSize);
      case RescueType.hazard:
        return Icon(Icons.warning, color: Colors.red, size: iconSize);
      case RescueType.gold:
        return Icon(Icons.monetization_on, color: Colors.yellow, size: iconSize);
       case RescueType.stone:
        return Icon(Icons.landscape, color: Colors.grey[400], size: iconSize);
       case RescueType.sand:
        return Icon(Icons.grain, color: Colors.brown, size: iconSize);
       case RescueType.water:
        return Icon(Icons.water_drop, color: Colors.blue, size: iconSize);
       case RescueType.lava:
        return Icon(Icons.local_fire_department, color: Colors.orange, size: iconSize);
      default:
        return const SizedBox.shrink();
    }
  }
}
