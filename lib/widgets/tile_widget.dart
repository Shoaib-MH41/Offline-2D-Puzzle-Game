import 'package:flutter/material.dart';
import '../models/tile.dart';

class TileWidget extends StatelessWidget {
  final Tile tile;
  final double size;
  final VoidCallback onTap;

  const TileWidget({
    Key? key,
    required this.tile,
    required this.size,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getColor(tile.type),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.2),
               blurRadius: 4,
               offset: const Offset(2, 2),
             )
          ]
        ),
        child: _getIcon(tile.type),
      ),
    );
  }

  Color _getColor(TileType type) {
    switch (type) {
      case TileType.red: return Colors.redAccent;
      case TileType.blue: return Colors.blueAccent;
      case TileType.green: return Colors.green;
      case TileType.yellow: return Colors.amber;
      case TileType.purple: return Colors.deepPurpleAccent;
      case TileType.empty: return Colors.transparent;
    }
  }

  Widget? _getIcon(TileType type) {
    IconData? icon;
    switch (type) {
      case TileType.red: icon = Icons.favorite; break;
      case TileType.blue: icon = Icons.water_drop; break;
      case TileType.green: icon = Icons.eco; break;
      case TileType.yellow: icon = Icons.star; break;
      case TileType.purple: icon = Icons.diamond; break;
      case TileType.empty: return null;
    }
    return Icon(icon, color: Colors.white, size: size * 0.5);
  }
}
