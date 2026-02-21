import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/adventure_scene.dart';
import '../widgets/rescue_widget.dart';
import '../services/storage_service.dart';
import '../models/level_config.dart';

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
  final List<dynamic> _effects = [];
  late AnimationController _shakeController;
  Widget? _overlayWidget;

  @override
  void initState() {
    super.initState();
    _gameProvider = context.read<GameProvider>();
    _gameProvider.addListener(_onGameUpdate);
    _eventSubscription = _gameProvider.events.listen(_handleEvent);
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeController.addListener(() => setState(() {}));

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
        _shakeController.animateTo(0.5, curve: Curves.easeIn).then((_) => _shakeController.reverse());
     } else if (event is ShakeEvent) {
        _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
     } else if (event is BombEvent) {
        setState(() {
           _effects.add(BlastEffectData(event.row, event.col));
        });
        _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
     } else if (event is MessageEvent) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(event.message, textAlign: TextAlign.center),
              duration: const Duration(milliseconds: 1000),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.black87,
            )
        );
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
    if (!mounted || _isDialogShowing) return;

    bool win = false;
    bool lose = false;
    String title = "";
    String message = "";

    if (_gameProvider.isLevelComplete) {
       win = true;
       title = "Stage Clear!";
       message = "Hero Rescued!";
    } else if (_gameProvider.isLevelFailed) {
       lose = true;
       title = "Stage Failed";
       message = "The Hero was lost.";
    } else if (_gameProvider.mode == GameMode.battle) {
         if (_gameProvider.monster != null && _gameProvider.monster!.isDead) {
             win = true;
             title = "Victory!";
             message = "You defeated the ${_gameProvider.monster!.name}!";
         } else if (_gameProvider.movesLeft <= 0) {
             lose = true;
             title = "Defeat";
             message = "Out of moves!";
         }
    } else if (_gameProvider.movesLeft <= 0) {
        lose = true;
        title = "Time's Up";
        message = "Out of moves!";
    }

    if (win || lose) {
       _isDialogShowing = true;
       if (win) {
          context.read<StorageService>().saveHighScore(_gameProvider.score);
          context.read<StorageService>().unlockLevel(_gameProvider.level + 1);
       }
       setState(() {
          _overlayWidget = WinLoseOverlay(
             isWin: win,
             title: title,
             message: message,
             score: _gameProvider.score,
             onNext: () {
                 setState(() { _overlayWidget = null; _isDialogShowing = false; });
                 _gameProvider.startNextLevel();
             },
             onRetry: () {
                 setState(() { _overlayWidget = null; _isDialogShowing = false; });
                 if (win) {
                    Navigator.pop(context);
                 } else {
                    _gameProvider.restartLevel();
                 }
             }
          );
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    double shake = sin(_shakeController.value * pi * 4) * 8 * _shakeController.value;

    int worldIndex = (_gameProvider.level - 1) ~/ 10;
    List<Color> bgColors;
    if (worldIndex == 0) {
      bgColors = [Colors.green[900]!, Colors.green[700]!];
    } else if (worldIndex == 1) {
      bgColors = [Colors.red[900]!, Colors.orange[900]!];
    } else if (worldIndex == 2) {
      bgColors = [Colors.purple[900]!, Colors.deepPurple[800]!];
    } else {
      bgColors = [Colors.black, Colors.blueGrey[900]!];
    }

    return Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: bgColors,
                )
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.pause_circle_filled, color: Colors.white70, size: 32),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Column(
                            children: [
                               Text("Level ${_gameProvider.level}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                               Text("${_gameProvider.movesLeft} Moves", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          ),
                          Column(
                            children: [
                               Text(_gameProvider.mode == GameMode.rescue ? "Energy" : "Score", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                               Text(_gameProvider.mode == GameMode.rescue ? "${_gameProvider.energy}" : "${_gameProvider.score}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          )
                        ],
                      ),
                    ),

                    // Top Area: Adventure or Rescue
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Transform.translate(
                          offset: Offset(shake, 0),
                          child: _gameProvider.mode == GameMode.rescue
                              ? const RescueWidget()
                              : const AdventureScene(),
                        ),
                      ),
                    ),

                    // Bottom Area: Board
                    Expanded(
                      flex: 6,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double availableWidth = constraints.maxWidth - 16;
                          final double availableHeight = constraints.maxHeight - 16;

                          // Aspect ratio 7:9 (cols:rows)
                          double boardWidth = availableWidth;
                          double boardHeight = availableWidth * (GameProvider.rows / GameProvider.cols);

                          if (boardHeight > availableHeight) {
                              boardHeight = availableHeight;
                              boardWidth = boardHeight * (GameProvider.cols / GameProvider.rows);
                          }

                          final double tileSize = boardWidth / GameProvider.cols;
                          final double offsetX = (constraints.maxWidth - boardWidth) / 2;
                          final double offsetY = (constraints.maxHeight - boardHeight) / 2;

                          return Stack(
                            children: [
                               Center(
                                 child: Container(
                                   width: boardWidth,
                                   height: boardHeight,
                                   decoration: BoxDecoration(
                                     color: Colors.black45,
                                     borderRadius: BorderRadius.circular(8),
                                   ),
                                   child: const BoardWidget(),
                                 ),
                               ),
                               // Effects
                               ..._effects.map((e) {
                                 if (e is ScorePopupData) {
                                   return Positioned(
                                     left: offsetX + (e.col * tileSize),
                                     top: offsetY + (e.row * tileSize),
                                     width: tileSize,
                                     height: tileSize,
                                     child: ScorePopupWidget(data: e, onComplete: () => _removeEffect(e.id)),
                                   );
                                 } else if (e is BlastEffectData) {
                                   return Positioned(
                                     left: offsetX + ((e.col - 1) * tileSize),
                                     top: offsetY + ((e.row - 1) * tileSize),
                                     width: tileSize * 3,
                                     height: tileSize * 3,
                                     child: BlastEffectWidget(data: e, onComplete: () => _removeEffect(e.id)),
                                   );
                                 }
                                 return const SizedBox.shrink();
                               }),
                            ],
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_overlayWidget ?? const SizedBox.shrink(),
          ],
        ),
    );
  }
}

class WinLoseOverlay extends StatefulWidget {
  final bool isWin;
  final String title;
  final String message;
  final int score;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  const WinLoseOverlay({
    super.key,
    required this.isWin,
    required this.title,
    required this.message,
    required this.score,
    required this.onNext,
    required this.onRetry,
  });

  @override
  State<WinLoseOverlay> createState() => _WinLoseOverlayState();
}

class _WinLoseOverlayState extends State<WinLoseOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.isWin ? Colors.amber : Colors.red, width: 3),
              boxShadow: [
                BoxShadow(color: widget.isWin ? Colors.amber.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.isWin ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
                  color: widget.isWin ? Colors.amber : Colors.redAccent, size: 80),
                const SizedBox(height: 16),
                Text(widget.title, style: TextStyle(color: widget.isWin ? Colors.amber : Colors.redAccent, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(widget.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 24),
                Text("Score: ${widget.score}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                      onPressed: widget.onRetry,
                      child: Text(widget.isWin ? "Map" : "Try Again", style: const TextStyle(color: Colors.white)),
                    ),
                    if (widget.isWin)
                      ElevatedButton(
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800]),
                         onPressed: widget.onNext,
                         child: const Text("Next Level", style: TextStyle(color: Colors.white)),
                      ),
                  ],
                )
              ],
            ),
          ),
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
