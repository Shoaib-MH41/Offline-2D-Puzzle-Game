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
      padding: const EdgeInsets.all(8.0),
      color: Colors.black87,
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
                    const Text(
                      "⚡",
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Energy: ${gameProvider.energy}",
                      style: TextStyle(
                        color: gameProvider.energy >= 10 ? Colors.white : Colors.grey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
                Text(
                  "Tap Pins to Pull!",
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
                  child: Container(
                    width: totalWidth,
                    height: totalHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: Stack(
                      children: [
                        // Simple Background
                        Container(color: Colors.black),

                        // Items
                        for (int r = 0; r < rows; r++)
                          for (int c = 0; c < cols; c++)
                            _buildRescueItem(context, rescueGrid[r][c], size, gameProvider, rescueGrid),
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

  Widget _buildRescueItem(BuildContext context, RescueItem item, double size, GameProvider provider, List<List<RescueItem>> grid) {
    if (item.type == RescueType.empty) return const SizedBox.shrink();

    // Check neighbors for Pin Logic
    bool isPinHead = false;

    if (item.type == RescueType.pin) {
       // Assuming horizontal pins
       bool leftIsPin = item.col > 0 && grid[item.row][item.col - 1].type == RescueType.pin;

       if (!leftIsPin) isPinHead = true; // Start of pin segment
    }

    return AnimatedPositioned(
      key: ValueKey(item.id),
      duration: const Duration(milliseconds: 200),
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
        child: Center(
          child: _buildEmoji(item.type, size, isPinHead),
        ),
      ),
    );
  }

  Widget _buildEmoji(RescueType type, double size, bool isPinHead) {
    String emoji = "";
    switch (type) {
      case RescueType.pin:
        emoji = isPinHead ? "📍" : "➖";
        break;
      case RescueType.hero:
        emoji = "🦸";
        break;
      case RescueType.enemy:
        emoji = "👹";
        break;
      case RescueType.exit:
        emoji = "🚪";
        break;
      case RescueType.lava:
        emoji = "🌋";
        break;
      case RescueType.water:
        emoji = "💧";
        break;
      case RescueType.stone:
        emoji = "🪨";
        break;
      case RescueType.sand:
        emoji = "🏜️";
        break;
      case RescueType.gold:
        emoji = "💰";
        break;
      default:
        return const SizedBox.shrink();
    }

    return Text(
      emoji,
      style: TextStyle(
        fontSize: size * 0.7,
        decoration: TextDecoration.none,
      ),
    );
  }
}
