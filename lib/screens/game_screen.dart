import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/adventure_scene.dart';
import '../services/storage_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class ScorePopupData {
  final String id;
  final int score;
  final int row;
  final int col;
  ScorePopupData(this.score, this.row, this.col) : id = DateTime.now().microsecondsSinceEpoch.toString();
}

class BlastEffectData {
  final String id;
  final int row;
  final int col;
  BlastEffectData(this.row, this.col) : id = DateTime.now().microsecondsSinceEpoch.toString();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  bool _isDialogShowing = false;
  late GameProvider _gameProvider;

  late StreamSubscription _eventSubscription;
  final List<dynamic> _effects = []; // Can be ScorePopupData or BlastEffectData

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _gameProvider = context.read<GameProvider>();
    _gameProvider.addListener(_onGameUpdate);

    _eventSubscription = _gameProvider.events.listen(_handleEvent);

    _shakeController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 400)
    );
    // Simpler shake:
    _shakeController.addListener(() {
       setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameProvider.generateGrid();
    });
  }

  @override
  void dispose() {
    _gameProvider.removeListener(_onGameUpdate);
    _eventSubscription.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleEvent(GameEvent event) {
     if (event is ScoreEvent) {
        setState(() {
          _effects.add(ScorePopupData(event.score, event.row, event.col));
        });
     } else if (event is DamageEvent) {
        // Small shake on damage? Or rely on ShakeEvent for big hits?
        // Let's keep small shake for damage feedback
        _shakeController.animateTo(0.5, curve: Curves.easeIn).then((_) => _shakeController.reverse());
     } else if (event is ShakeEvent) {
        // Big shake for combos
        _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
     } else if (event is BombEvent) {
        setState(() {
           _effects.add(BlastEffectData(event.row, event.col));
        });
        _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
     }
  }

  void _removeEffect(String id) {
    if (mounted) {
      setState(() {
        _effects.removeWhere((e) => (e is ScorePopupData && e.id == id) || (e is BlastEffectData && e.id == id));
      });
    }
  }

  void _onGameUpdate() {
    if (!mounted) return;
    if (_isDialogShowing) return;

    if (_gameProvider.monster.currentHp <= 0) {
       _isDialogShowing = true;
       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (ctx) => AlertDialog(
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
           title: const Text("Victory!", textAlign: TextAlign.center),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
               const SizedBox(height: 16),
               Text("You defeated the ${_gameProvider.monster.name}!", textAlign: TextAlign.center),
             ],
           ),
           actions: [
             TextButton(
               onPressed: () {
                 _isDialogShowing = false;
                 Navigator.pop(ctx);
                 _gameProvider.startNextLevel();
               },
               child: const Text("Next Level", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             )
           ],
         ),
       );
    } else if (_gameProvider.movesLeft <= 0) {
       _isDialogShowing = true;
       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (ctx) => AlertDialog(
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
           title: const Text("Level Failed", textAlign: TextAlign.center),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Icon(Icons.sentiment_very_dissatisfied, color: Colors.redAccent, size: 60),
               const SizedBox(height: 16),
               const Text("Out of moves! The monster survived.", textAlign: TextAlign.center),
             ],
           ),
           actions: [
             TextButton(
               onPressed: () {
                 _isDialogShowing = false;
                 Navigator.pop(ctx);
                 _gameProvider.restartLevel();
               },
               child: const Text("Try Again", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             )
           ],
         ),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shake offset
    double shake = sin(_shakeController.value * pi * 4) * 8 * _shakeController.value;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
         if (didPop) {
           final storage = context.read<StorageService>();
           await storage.saveHighScore(context.read<GameProvider>().score);
         }
      },
      child: Scaffold(
        body: Column(
          children: [
            // Top Area: Adventure
            Expanded(
              flex: 3,
              child: Transform.translate(
                offset: Offset(shake, 0),
                child: const AdventureScene(),
              ),
            ),

            // Bottom Area: Board
            Expanded(
              flex: 7,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double availableWidth = constraints.maxWidth - 32;
                      final double availableHeight = constraints.maxHeight - 32; // 16*2 padding

                      final double tileWidth = availableWidth / GameProvider.cols;
                      final double tileHeight = availableHeight / GameProvider.rows;
                      final double size = tileWidth < tileHeight ? tileWidth : tileHeight;

                      final double offsetX = (constraints.maxWidth - (size * GameProvider.cols)) / 2;
                      final double offsetY = (constraints.maxHeight - (size * GameProvider.rows)) / 2;

                      return Stack(
                        children: [
                           Positioned.fill(
                             child: Opacity(
                               opacity: 0.05,
                               child: GridPaper(color: Colors.white, interval: 50),
                             ),
                           ),
                           const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: BoardWidget(),
                          ),

                          // Effects
                          ..._effects.map((e) {
                            if (e is ScorePopupData) {
                              return Positioned(
                                key: ValueKey(e.id),
                                left: offsetX + (e.col * size),
                                top: offsetY + (e.row * size),
                                width: size,
                                height: size,
                                child: ScorePopupWidget(
                                  data: e,
                                  onComplete: () => _removeEffect(e.id),
                                ),
                              );
                            } else if (e is BlastEffectData) {
                              // Blast covers 3x3 if possible, or just huge explosion at center
                              return Positioned(
                                key: ValueKey(e.id),
                                left: offsetX + ((e.col - 1) * size), // Center on tile but larger
                                top: offsetY + ((e.row - 1) * size),
                                width: size * 3,
                                height: size * 3,
                                child: BlastEffectWidget(
                                  data: e,
                                  onComplete: () => _removeEffect(e.id),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),

                          // Back Button
                          Positioned(
                            top: 16,
                            left: 16,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlastEffectWidget extends StatefulWidget {
  final BlastEffectData data;
  final VoidCallback onComplete;

  const BlastEffectWidget({super.key, required this.data, required this.onComplete});

  @override
  State<BlastEffectWidget> createState() => _BlastEffectWidgetState();
}

class _BlastEffectWidgetState extends State<BlastEffectWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0))
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.orangeAccent.withValues(alpha: 0.8),
                Colors.redAccent.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScorePopupWidget extends StatefulWidget {
  final ScorePopupData data;
  final VoidCallback onComplete;

  const ScorePopupWidget({super.key, required this.data, required this.onComplete});

  @override
  State<ScorePopupWidget> createState() => _ScorePopupWidgetState();
}

class _ScorePopupWidgetState extends State<ScorePopupWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0))
    );
    _slide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Center(
          child: Text(
            '+${widget.data.score}',
            style: TextStyle(
              color: widget.data.score >= 50 ? Colors.purpleAccent : (widget.data.score >= 40 ? Colors.redAccent : Colors.amberAccent),
              fontSize: widget.data.score >= 40 ? 32 : 24,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}
