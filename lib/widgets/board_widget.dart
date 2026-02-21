import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/tile.dart';
import 'tile_widget.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            final double availableHeight = constraints.maxHeight;

            // Calculate tile size
            final double tileWidth = availableWidth / GameProvider.cols;
            final double tileHeight = availableHeight / GameProvider.rows;
            // Use the smaller dimension to keep tiles square
            final double size = tileWidth < tileHeight ? tileWidth : tileHeight;
            final double tileSize = size * 0.88; // Proper gap for shadows

            // Center the grid
            final double offsetX = (availableWidth - (size * GameProvider.cols)) / 2;
            final double offsetY = (availableHeight - (size * GameProvider.rows)) / 2;

            final List<Widget> tileWidgets = [];

            // Iterate over the grid
            for (var row in game.grid) {
              for (var tile in row) {
                if (tile.type == TileType.empty) continue;

                tileWidgets.add(
                  AnimatedPositioned(
                    key: ValueKey(tile.id),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: offsetX + (tile.col * size) + (size - tileSize) / 2,
                    top: offsetY + (tile.row * size) + (size - tileSize) / 2,
                    width: tileSize,
                    height: tileSize,
                    child: _TileGestureDetector(
                      onSwipe: (dir) {
                        game.handleSwap(tile.row, tile.col, dir);
                      },
                      child: TileWidget(
                        tile: tile,
                        size: tileSize,
                      ),
                    ),
                  )
                );
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: tileWidgets,
            );
          },
        );
      },
    );
  }
}

class _TileGestureDetector extends StatefulWidget {
  final Widget child;
  final Function(Direction) onSwipe;

  const _TileGestureDetector({required this.child, required this.onSwipe});

  @override
  State<_TileGestureDetector> createState() => _TileGestureDetectorState();
}

class _TileGestureDetectorState extends State<_TileGestureDetector> {
  Offset? _startPos;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _startPos = details.localPosition,
      onPanUpdate: (details) {
         if (_startPos == null) return;
         final dy = details.localPosition.dy - _startPos!.dy;
         final dx = details.localPosition.dx - _startPos!.dx;

         // Threshold for swipe detection (e.g. 10% of tile or fixed px)
         // Using fixed px for simplicity
         if (dx.abs() > 15 || dy.abs() > 15) {
            Direction? dir;
            if (dx.abs() > dy.abs()) {
               dir = dx > 0 ? Direction.right : Direction.left;
            } else {
               dir = dy > 0 ? Direction.down : Direction.up;
            }
            widget.onSwipe(dir);
            _startPos = null; // Reset to prevent multiple triggers
         }
      },
      onPanEnd: (_) => _startPos = null,
      child: widget.child,
    );
  }
}
