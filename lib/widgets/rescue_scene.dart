import 'dart:math';
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
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A), // Darker background
      ),
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
                    Icon(
                      Icons.bolt,
                      color: gameProvider.energy >= 10 ? Colors.yellowAccent : Colors.grey,
                      size: 28,
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
                      border: Border.all(color: const Color(0xFF4A4A4A), width: 8), // Frame
                      boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 10)],
                    ),
                    child: Stack(
                      children: [
                        // Dungeon Background
                        Positioned.fill(
                           child: CustomPaint(
                             painter: DungeonBackgroundPainter(rows: rows, cols: cols, size: size),
                           ),
                        ),

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
    bool isPinTail = false;

    if (item.type == RescueType.pin) {
       // Assuming horizontal pins
       bool leftIsPin = item.col > 0 && grid[item.row][item.col - 1].type == RescueType.pin;
       bool rightIsPin = item.col < grid[0].length - 1 && grid[item.row][item.col + 1].type == RescueType.pin;

       if (!leftIsPin) isPinHead = true; // Start of pin segment
       if (!rightIsPin) isPinTail = true; // End of pin segment
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
        child: _buildItemWidget(item.type, size, isPinHead, isPinTail, provider.energy >= 10),
      ),
    );
  }

  Widget _buildItemWidget(RescueType type, double size, bool isHead, bool isTail, bool canPull) {
    switch (type) {
      case RescueType.pin:
        return PinWidget(size: size, isHead: isHead, isTail: isTail, canPull: canPull);
      case RescueType.hero:
        return HeroWidget(size: size);
      case RescueType.enemy:
        return Icon(Icons.adb, color: Colors.redAccent, size: size * 0.7);
      case RescueType.exit:
        return ExitWidget(size: size);
      case RescueType.lava:
        return FluidWidget(size: size, type: FluidType.lava);
      case RescueType.water:
        return FluidWidget(size: size, type: FluidType.water);
      case RescueType.stone:
        return StoneWidget(size: size);
      case RescueType.sand:
        return SandWidget(size: size);
      case RescueType.gold:
        return Icon(Icons.monetization_on, color: Colors.yellow, size: size * 0.7);
      default:
        return const SizedBox.shrink();
    }
  }
}

// --- Visual Widgets ---

class DungeonBackgroundPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double size;

  DungeonBackgroundPainter({required this.rows, required this.cols, required this.size});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()..color = const Color(0xFF222222);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final Paint linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw Bricks
    for (int r = 0; r <= rows; r++) {
       canvas.drawLine(Offset(0, r * this.size), Offset(size.width, r * this.size), linePaint);

       if (r < rows) {
         for (int c = 0; c <= cols; c++) {
            double x = c * this.size;
            if (r % 2 == 1) x += this.size / 2; // Staggered
            canvas.drawLine(Offset(x, r * this.size), Offset(x, (r+1) * this.size), linePaint);
         }
       }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeroWidget extends StatelessWidget {
  final double size;
  const HeroWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.person, color: Colors.blue[300], size: size * 0.7),
        Positioned(
          top: size * 0.05,
          child: Icon(Icons.star, color: Colors.amber, size: size * 0.35), // Crown
        ),
        Positioned(
          bottom: size * 0.1,
          child: Container(
            width: size * 0.6,
            height: size * 0.1,
            decoration: BoxDecoration(color: Colors.red[900], borderRadius: BorderRadius.circular(4)), // Cape
          ),
        )
      ],
    );
  }
}

class ExitWidget extends StatelessWidget {
  final double size;
  const ExitWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
     return Stack(
        alignment: Alignment.center,
        children: [
           Container(
             width: size * 0.8,
             height: size * 0.9,
             decoration: BoxDecoration(
                color: Colors.brown[800],
                border: Border.all(color: Colors.amber, width: 2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(100)),
             ),
           ),
           Icon(Icons.door_back_door, color: Colors.amberAccent, size: size * 0.6),
        ],
     );
  }
}

class StoneWidget extends StatelessWidget {
  final double size;
  const StoneWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[800]!, width: 2),
      ),
      child: CustomPaint(
         painter: CracksPainter(),
      ),
    );
  }
}

class CracksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.2);
    path.lineTo(size.width * 0.4, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height * 0.8);

    path.moveTo(size.width * 0.7, size.height * 0.1);
    path.lineTo(size.width * 0.6, size.height * 0.4);

    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SandWidget extends StatelessWidget {
  final double size;
  const SandWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: const Color(0xFFE6C288),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomPaint(
        painter: SandGrainPainter(),
      ),
    );
  }
}

class SandGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.brown.withValues(alpha: 0.3);
    final random = Random(42); // Fixed seed for consistent look
    for(int i=0; i<20; i++) {
       canvas.drawCircle(
         Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
         1,
         paint
       );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum FluidType { lava, water }

class FluidWidget extends StatelessWidget {
  final double size;
  final FluidType type;
  const FluidWidget({super.key, required this.size, required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = type == FluidType.lava
       ? [Colors.orange, Colors.red]
       : [Colors.blue, Colors.cyan];

    return Container(
       margin: const EdgeInsets.all(1),
       decoration: BoxDecoration(
          gradient: LinearGradient(
             begin: Alignment.topCenter,
             end: Alignment.bottomCenter,
             colors: colors,
          ),
          borderRadius: BorderRadius.circular(4),
       ),
       child: CustomPaint(
         painter: BubblePainter(),
       ),
    );
  }
}

class BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
     final paint = Paint()
       ..color = Colors.white.withValues(alpha: 0.4)
       ..style = PaintingStyle.fill;

     final random = Random(123);
     for(int i=0; i<5; i++) {
        canvas.drawCircle(
           Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
           random.nextDouble() * 3 + 1,
           paint
        );
     }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PinWidget extends StatelessWidget {
  final double size;
  final bool isHead;
  final bool isTail;
  final bool canPull;

  const PinWidget({
    super.key,
    required this.size,
    required this.isHead,
    required this.isTail,
    required this.canPull,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: PinPainter(isHead: isHead, isTail: isTail, canPull: canPull),
    );
  }
}

class PinPainter extends CustomPainter {
  final bool isHead;
  final bool isTail;
  final bool canPull;

  PinPainter({required this.isHead, required this.isTail, required this.canPull});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint barPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD700), Color(0xFFB8860B)], // Gold Gradient
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final double barHeight = size.height * 0.4;
    final double top = (size.height - barHeight) / 2;

    double left = 0;
    double width = size.width;

    if (isHead) {
      left = size.width * 0.15;
      width -= left;
    }

    if (isTail) {
      width -= size.width * 0.05;
    }

    final RRect rodRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(left, top, width, barHeight),
      topLeft: isHead ? const Radius.circular(4) : Radius.zero,
      bottomLeft: isHead ? const Radius.circular(4) : Radius.zero,
      topRight: isTail ? const Radius.circular(4) : Radius.zero,
      bottomRight: isTail ? const Radius.circular(4) : Radius.zero,
    );
    canvas.drawRRect(rodRect, barPaint);

    final Paint shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(left, top + barHeight * 0.1, width, barHeight * 0.3), shinePaint);

    if (isHead) {
      final Paint ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height * 0.08
        ..color = canPull ? Colors.yellowAccent : const Color(0xFFDAA520);

      if (canPull) {
          ringPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      }

      final double ringCenterY = size.height / 2;
      final double ringCenterX = size.width * 0.08;
      final double ringRadius = size.height * 0.15;

      canvas.drawCircle(Offset(ringCenterX, ringCenterY), ringRadius, ringPaint);

      final Paint connectorPaint = Paint()
        ..color = const Color(0xFFB8860B)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(ringCenterX + ringRadius, top + barHeight * 0.25, left - (ringCenterX + ringRadius), barHeight * 0.5), connectorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
