import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import 'world_map_screen.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  Future<int>? _highScoreFuture;

  @override
  void initState() {
    super.initState();
    _refreshHighScore();
  }

  void _refreshHighScore() {
    setState(() {
      _highScoreFuture = context.read<StorageService>().getHighScore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              const Icon(Icons.extension, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'PUZZLE\nQUEST',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(2, 2))],
                ),
              ),
              const SizedBox(height: 40),

              // High Score
              FutureBuilder<int>(
                future: _highScoreFuture,
                builder: (context, snapshot) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'High Score: ${snapshot.data ?? 0}',
                      style: const TextStyle(fontSize: 20, color: Colors.amberAccent, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),

              // Play Button
              _buildButton(
                label: 'PLAY',
                icon: Icons.play_arrow,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WorldMapScreen()),
                  ).then((_) {
                    _refreshHighScore();
                  });
                },
              ),
               const SizedBox(height: 20),

               // Settings Button
              _buildButton(
                label: 'SETTINGS',
                icon: Icons.settings,
                isSecondary: true,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Settings coming soon!')),
                   );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white.withValues(alpha: 0.1) : Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: isSecondary ? 0 : 8,
          shadowColor: Colors.orangeAccent.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
