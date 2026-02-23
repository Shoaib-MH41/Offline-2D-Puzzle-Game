import 'package:flutter/material.dart';
import '../models/tile.dart';

class TileWidget extends StatelessWidget {
  final Tile tile;
  final double size;

  const TileWidget({
    super.key,
    required this.tile,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (tile.type == TileType.empty) return const SizedBox.shrink();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main Emoji
          Text(
            _getEmoji(tile.type),
            style: TextStyle(
              fontSize: size * 0.7,
              decoration: TextDecoration.none,
            ),
          ),

          // Timed Bomb Counter
          if (tile.type == TileType.timedBomb)
            Positioned(
              bottom: 0,
              right: 0,
              child: Text(
                "${tile.turnsLeft}",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                  shadows: const [
                    Shadow(color: Colors.white, blurRadius: 2),
                  ],
                ),
              ),
            ),

          // Lock Overlay
          if (tile.isLocked)
            Container(
              width: size,
              height: size,
              color: Colors.black.withValues(alpha: 0.3),
              alignment: Alignment.center,
              child: Text(
                "🔒",
                style: TextStyle(fontSize: size * 0.5),
              ),
            ),
        ],
      ),
    );
  }

  String _getEmoji(TileType type) {
    switch (type) {
      case TileType.sword: return "⚔️";
      case TileType.shield: return "🛡️";
      case TileType.crystal: return "💎";
      case TileType.heart: return "❤️";
      case TileType.bomb: return "💣";
      case TileType.stone: return "🪨";
      case TileType.ice: return "❄️";
      case TileType.poison: return "☠️";
      case TileType.key: return "🔑";
      case TileType.timedBomb: return "⏲️";
      case TileType.power: return "⚡";
      case TileType.rocket: return "🚀";
      case TileType.lamp: return "💡";
      case TileType.empty: return "";
    }
  }
}
