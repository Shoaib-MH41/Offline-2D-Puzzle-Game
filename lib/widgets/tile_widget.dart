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

    final isBomb = tile.isBomb || tile.type == TileType.bomb;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(tile.type),
        ),
        borderRadius: BorderRadius.circular(size * 0.2), // Rounded
        boxShadow: [
           BoxShadow(
             color: _getColor(tile.type).withValues(alpha: 0.5),
             blurRadius: 4,
             offset: const Offset(0, 4),
           ),
           if (isBomb)
              BoxShadow(
                color: Colors.orangeAccent.withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 2,
              )
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle inner glow/pattern
          Container(
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               color: Colors.white.withValues(alpha: 0.1),
             ),
             width: size * 0.8,
             height: size * 0.8,
          ),
          _getIcon(tile.type, size),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(TileType type) {
    Color base = _getColor(type);
    Color dark = Color.lerp(base, Colors.black, 0.4)!;
    Color light = Color.lerp(base, Colors.white, 0.2)!;

    // Reverse gradient for depth
    return [light, base, dark];
  }

  Color _getColor(TileType type) {
    switch (type) {
      case TileType.sword: return const Color(0xFFE57373); // Red
      case TileType.shield: return const Color(0xFF64B5F6); // Blue
      case TileType.crystal: return const Color(0xFFBA68C8); // Purple
      case TileType.heart: return const Color(0xFF81C784); // Green
      case TileType.bomb: return const Color(0xFF424242); // Dark/Black
      case TileType.empty: return Colors.transparent;
    }
  }

  Widget _getIcon(TileType type, double size) {
    IconData icon;
    double iconSize = size * 0.6;
    Color color = Colors.white.withValues(alpha: 0.95);

    switch (type) {
      case TileType.sword:
        icon = Icons.colorize;
        return Transform.rotate(
          angle: 3.14 / 4, // 45 degrees
          child: Icon(icon, color: color, size: iconSize),
        );
      case TileType.shield:
        icon = Icons.shield;
        break;
      case TileType.crystal:
        icon = Icons.diamond;
        break;
      case TileType.heart:
        icon = Icons.favorite;
        break;
      case TileType.bomb:
        icon = Icons.whatshot;
        color = Colors.orangeAccent;
        break;
      case TileType.empty:
        return const SizedBox.shrink();
    }

    return Icon(icon, color: color, size: iconSize);
  }
}
