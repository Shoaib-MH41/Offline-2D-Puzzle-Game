import 'package:flutter/material.dart';
import '../models/tile.dart';

class TileWidget extends StatefulWidget {
  final Tile tile;
  final double size;
  final VoidCallback onTap;

  const TileWidget({
    super.key,
    required this.tile,
    required this.size,
    required this.onTap,
  });

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tile.type == TileType.empty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getGradientColors(widget.tile.type),
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
               BoxShadow(
                 color: _getColor(widget.tile.type).withValues(alpha: 0.5),
                 blurRadius: 6,
                 offset: const Offset(2, 4),
               ),
               if (widget.tile.isBomb)
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5
            ),
          ),
          child: Center(
            child: widget.tile.isBomb
              ? Icon(Icons.bolt, color: Colors.white, size: widget.size * 0.6)
              : _getIcon(widget.tile.type, widget.size),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(TileType type) {
    Color base = _getColor(type);
    return [
      base,
      Color.lerp(base, Colors.black, 0.3)!,
    ];
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

  Widget? _getIcon(TileType type, double size) {
    IconData? icon;
    switch (type) {
      case TileType.red: icon = Icons.favorite; break;
      case TileType.blue: icon = Icons.water_drop; break;
      case TileType.green: icon = Icons.eco; break;
      case TileType.yellow: icon = Icons.star; break;
      case TileType.purple: icon = Icons.diamond; break;
      case TileType.empty: return null;
    }
    return Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: size * 0.5);
  }
}
