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

    final isBomb = tile.type == TileType.bomb || tile.type == TileType.timedBomb;
    final isPower = tile.type == TileType.power;

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
           if (isBomb || isPower)
              BoxShadow(
                color: (isBomb ? Colors.redAccent : Colors.yellowAccent).withValues(alpha: 0.6),
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

          if (tile.type == TileType.timedBomb)
             Center(
               child: Text(
                 "${tile.turnsLeft}",
                 style: TextStyle(
                   color: Colors.redAccent,
                   fontWeight: FontWeight.bold,
                   fontSize: size * 0.5,
                   shadows: const [Shadow(color: Colors.black, blurRadius: 2)]
                 )
               ),
             )
          else
             _getIcon(tile.type, size),

          if (tile.type == TileType.stone && tile.hp == 1)
             Icon(Icons.broken_image, color: Colors.black.withValues(alpha: 0.4), size: size * 0.5),

          if (tile.isLocked)
             Container(
               decoration: BoxDecoration(
                 color: Colors.black.withValues(alpha: 0.6),
                 borderRadius: BorderRadius.circular(size * 0.2),
               ),
               child: Center(
                 child: Icon(Icons.lock, color: Colors.white, size: size * 0.5),
               ),
             ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(TileType type) {
    Color base = _getColor(type);
    Color dark = Color.lerp(base, Colors.black, 0.4) ?? Colors.black;
    Color light = Color.lerp(base, Colors.white, 0.2) ?? Colors.white;

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
      case TileType.stone: return const Color(0xFF757575); // Grey
      case TileType.ice: return const Color(0xFF4DD0E1); // Cyan
      case TileType.poison: return const Color(0xFF66BB6A); // Green Poison
      case TileType.key: return const Color(0xFFFFD54F); // Amber Key
      case TileType.timedBomb: return const Color(0xFF212121); // Black Bomb
      case TileType.power: return const Color(0xFFFFEE58); // Yellow Power
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
      case TileType.stone:
        icon = Icons.landscape;
        break;
      case TileType.ice:
        icon = Icons.ac_unit;
        break;
      case TileType.poison:
        icon = Icons.dangerous;
        color = Colors.purpleAccent;
        break;
      case TileType.key:
        icon = Icons.vpn_key;
        color = Colors.black87;
        break;
      case TileType.timedBomb:
        // Handled in build method with text
        return const SizedBox.shrink();
      case TileType.power:
        icon = Icons.flash_on;
        color = Colors.redAccent;
        break;
      case TileType.empty:
        return const SizedBox.shrink();
    }

    return Icon(icon, color: color, size: iconSize);
  }
}
