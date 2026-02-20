import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/tile.dart';
import 'tile_widget.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({Key? key}) : super(key: key);

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
            final double tileSize = size * 0.95; // Add a small gap by reducing size slightly

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
                    child: TileWidget(
                      tile: tile,
                      size: tileSize,
                      onTap: () => game.handleTap(tile.row, tile.col),
                    ),
                  )
                );
              }
            }

            return Stack(
              children: tileWidgets,
            );
          },
        );
      },
    );
  }
}
