import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/games/snake/retro_snake_game.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class RetroSnakeScreen extends StatefulWidget {
  const RetroSnakeScreen({super.key});

  @override
  State<RetroSnakeScreen> createState() => _RetroSnakeScreenState();
}

class _RetroSnakeScreenState extends State<RetroSnakeScreen> with WidgetsBindingObserver {
  late final RetroSnakeGame _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = RetroSnakeGame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _game.pauseGame();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _game,
      child: const _RetroSnakeView(),
    );
  }
}

class _RetroSnakeView extends StatelessWidget {
  const _RetroSnakeView();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double mediaWidth = size.width;
    double mediaHeight = size.height;
    final game = context.read<RetroSnakeGame>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          game.pauseGame();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.04),
            child: Column(
              children: [
                SizedBox(height: mediaHeight * 0.012),

                // Header Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
                      onPressed: () {
                        game.pauseGame();
                        Navigator.pop(context);
                      },
                    ),
                    Text(
                      'RETRO SNAKE',
                      style: TextStyle(
                        color: AppTheme.yellow300,
                        fontSize: mediaWidth * 0.055,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings, color: AppTheme.white),
                          onPressed: () {
                            game.pauseGame();
                            _showSettingsDialog(context, game);
                          },
                        ),
                        Selector<RetroSnakeGame, bool>(
                          selector: (_, g) => g.isPaused,
                          builder: (_, isPaused, child) {
                            return IconButton(
                              icon: Icon(
                                isPaused ? Icons.play_arrow : Icons.pause,
                                color: AppTheme.yellow300,
                              ),
                              onPressed: () => game.togglePause(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: mediaHeight * 0.008),

                // Score / Best / Level Dashboard
                Selector<RetroSnakeGame, _ScoreData>(
                  selector: (_, g) => _ScoreData(g.score, g.bestScore, g.level),
                  builder: (_, scoreData, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.yellow300.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildScoreItem('SCORE', '${scoreData.score}'),
                          _buildScoreItem('BEST', '${scoreData.bestScore}'),
                          _buildScoreItem('LEVEL', scoreData.level.toString().padLeft(2, '0')),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: mediaHeight * 0.012),

                // Game Board Area
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: RetroSnakeGame.cols / RetroSnakeGame.rows,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0B18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.yellow300.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.yellow300.withValues(alpha: 0.15),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) {
                              double dx = details.delta.dx;
                              double dy = details.delta.dy;
                              if (dx.abs() > dy.abs()) {
                                if (dx > 1.2) {
                                  game.changeDirection(Direction.right);
                                } else if (dx < -1.2) {
                                  game.changeDirection(Direction.left);
                                }
                              } else {
                                if (dy > 1.2) {
                                  game.changeDirection(Direction.down);
                                } else if (dy < -1.2) {
                                  game.changeDirection(Direction.up);
                                }
                              }
                            },
                            child: Stack(
                              children: [
                                // Custom Paint Game Board (ListenableBuilder minimizes rebuild scope)
                                ListenableBuilder(
                                  listenable: game,
                                  builder: (context, _) {
                                    return RepaintBoundary(
                                      child: CustomPaint(
                                        size: Size.infinite,
                                        painter: _SnakeGamePainter(
                                          snake: game.snake,
                                          collectible: game.collectible,
                                          direction: game.currentDirection,
                                          snakeColorOption: game.snakeColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Pause Overlay
                                Selector<RetroSnakeGame, _OverlayData>(
                                  selector: (_, g) => _OverlayData(g.isPaused, g.isGameOver, g.isNewHighScore, g.score, g.bestScore),
                                  builder: (_, data, child) {
                                    if (data.isPaused && !data.isGameOver) {
                                      return Container(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'PAUSED',
                                                style: TextStyle(
                                                  color: AppTheme.yellow300,
                                                  fontSize: mediaWidth * 0.08,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 4,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.yellow300,
                                                  foregroundColor: Colors.black,
                                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                onPressed: () => game.togglePause(),
                                                icon: const Icon(Icons.play_arrow),
                                                label: const Text(
                                                  'RESUME',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    if (data.isGameOver) {
                                      return Container(
                                        color: Colors.black.withValues(alpha: 0.88),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (data.isNewHighScore)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 8.0),
                                                    child: Text(
                                                      '🔥 NEW HIGH SCORE! 🔥',
                                                      style: TextStyle(
                                                        color: AppTheme.yellow300,
                                                        fontSize: mediaWidth * 0.045,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                Text(
                                                  'GAME OVER',
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                    fontSize: mediaWidth * 0.08,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 3,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'FINAL SCORE: ${data.score}',
                                                  style: TextStyle(
                                                    color: AppTheme.white,
                                                    fontSize: mediaWidth * 0.045,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'BEST SCORE: ${data.bestScore}',
                                                  style: TextStyle(
                                                    color: AppTheme.white38,
                                                    fontSize: mediaWidth * 0.038,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.yellow300,
                                                    foregroundColor: Colors.black,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 32,
                                                      vertical: 12,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  onPressed: () => game.startGame(),
                                                  child: const Text(
                                                    'PLAY AGAIN',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                    'EXIT GAME',
                                                    style: TextStyle(
                                                      color: AppTheme.white38,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: mediaHeight * 0.01),

                // Retro D-Pad Controller (Stateless & immediate response)
                Container(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      _buildDpadButton(Icons.keyboard_arrow_up, () {
                        HapticFeedback.selectionClick();
                        game.changeDirection(Direction.up);
                      }),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDpadButton(Icons.keyboard_arrow_left, () {
                            HapticFeedback.selectionClick();
                            game.changeDirection(Direction.left);
                          }),
                          const SizedBox(width: 50),
                          _buildDpadButton(Icons.keyboard_arrow_right, () {
                            HapticFeedback.selectionClick();
                            game.changeDirection(Direction.right);
                          }),
                        ],
                      ),
                      _buildDpadButton(Icons.keyboard_arrow_down, () {
                        HapticFeedback.selectionClick();
                        game.changeDirection(Direction.down);
                      }),
                    ],
                  ),
                ),

                SizedBox(height: mediaHeight * 0.008),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDpadButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.cardBackground,
          foregroundColor: AppTheme.yellow300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: AppTheme.yellow300.withValues(alpha: 0.3),
            ),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, RetroSnakeGame game) {
    SnakeColorOption selectedColor = game.snakeColor;
    StartingSpeed selectedSpeed = game.startingSpeed;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.yellow300.withValues(alpha: 0.5), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SNAKE SETTINGS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.yellow300,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Snake Color',
                      style: TextStyle(color: AppTheme.white70, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SnakeColorOption.values.map((colorOption) {
                        bool isSelected = selectedColor == colorOption;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedColor = colorOption);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colorOption.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppTheme.white : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: colorOption.color.withValues(alpha: 0.5), blurRadius: 8)]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Starting Speed: ${selectedSpeed.name}',
                      style: TextStyle(color: AppTheme.white70, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.yellow300,
                        inactiveTrackColor: AppTheme.sliderInactive,
                        thumbColor: AppTheme.primaryAccent,
                        overlayColor: AppTheme.primaryAccent.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: selectedSpeed.index.toDouble(),
                        min: 0,
                        max: StartingSpeed.values.length - 1,
                        divisions: StartingSpeed.values.length - 1,
                        onChanged: (value) {
                          setState(() {
                            selectedSpeed = StartingSpeed.values[value.toInt()];
                          });
                        },
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Slow', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                        Text('Fast', style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.yellow300,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        game.updateSettings(selectedColor, selectedSpeed);
                        Navigator.pop(ctx);
                      },
                      child: const Text('APPLY & CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ScoreData {
  final int score;
  final int bestScore;
  final int level;

  _ScoreData(this.score, this.bestScore, this.level);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ScoreData &&
          runtimeType == other.runtimeType &&
          score == other.score &&
          bestScore == other.bestScore &&
          level == other.level;

  @override
  int get hashCode => Object.hash(score, bestScore, level);
}

class _OverlayData {
  final bool isPaused;
  final bool isGameOver;
  final bool isNewHighScore;
  final int score;
  final int bestScore;

  _OverlayData(this.isPaused, this.isGameOver, this.isNewHighScore, this.score, this.bestScore);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _OverlayData &&
          runtimeType == other.runtimeType &&
          isPaused == other.isPaused &&
          isGameOver == other.isGameOver &&
          isNewHighScore == other.isNewHighScore &&
          score == other.score &&
          bestScore == other.bestScore;

  @override
  int get hashCode => Object.hash(isPaused, isGameOver, isNewHighScore, score, bestScore);
}

class _SnakeGamePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Collectible? collectible;
  final Direction direction;
  final SnakeColorOption snakeColorOption;

  _SnakeGamePainter({
    required this.snake,
    required this.collectible,
    required this.direction,
    required this.snakeColorOption,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / RetroSnakeGame.cols;
    final double cellHeight = size.height / RetroSnakeGame.rows;

    // 1. Draw Retro Grid Lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    for (int col = 0; col <= RetroSnakeGame.cols; col++) {
      double x = col * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int row = 0; row <= RetroSnakeGame.rows; row++) {
      double y = row * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Collectible (Food)
    if (collectible != null) {
      final pos = collectible!.position;
      final double cx = pos.x * cellWidth + cellWidth / 2;
      final double cy = pos.y * cellHeight + cellHeight / 2;
      final double radius = min(cellWidth, cellHeight) * 0.42;

      Color foodColor;
      switch (collectible!.type) {
        case CollectibleType.note:
          foodColor = const Color(0xFF00FF66); // Neon Green
          break;
        case CollectibleType.cassette:
          foodColor = const Color(0xFF00E5FF); // Neon Cyan
          break;
        case CollectibleType.vinyl:
          foodColor = const Color(0xFFFF00FF); // Neon Magenta
          break;
      }

      // Glow effect
      final glowPaint = Paint()
        ..color = foodColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(cx, cy), radius * 1.3, glowPaint);

      // Main shape
      final foodPaint = Paint()
        ..color = foodColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), radius, foodPaint);

      // Inner highlight
      final innerHighlight = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx - radius * 0.25, cy - radius * 0.25), radius * 0.28, innerHighlight);
    }

    // 3. Draw Snake Body & Glow
    if (snake.isEmpty) return;
    
    final Color baseSnakeColor = snakeColorOption.color;

    final glowPaint = Paint()
      ..color = baseSnakeColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = snake.length - 1; i >= 0; i--) {
      final pt = snake[i];
      final double x = pt.x * cellWidth;
      final double y = pt.y * cellHeight;

      if (i == 0) {
        // Draw Head
        final headPaint = Paint()
          ..color = baseSnakeColor
          ..style = PaintingStyle.fill;

        final rect = Rect.fromLTWH(x + 1, y + 1, cellWidth - 2, cellHeight - 2);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cellWidth * 0.4)), glowPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cellWidth * 0.4)), headPaint);

        // Draw Eyes based on Direction
        final eyePaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;

        double eyeRadius = cellWidth * 0.12;
        Offset eye1 = Offset.zero;
        Offset eye2 = Offset.zero;

        switch (direction) {
          case Direction.up:
            eye1 = Offset(x + cellWidth * 0.3, y + cellHeight * 0.3);
            eye2 = Offset(x + cellWidth * 0.7, y + cellHeight * 0.3);
            break;
          case Direction.down:
            eye1 = Offset(x + cellWidth * 0.3, y + cellHeight * 0.7);
            eye2 = Offset(x + cellWidth * 0.7, y + cellHeight * 0.7);
            break;
          case Direction.left:
            eye1 = Offset(x + cellWidth * 0.3, y + cellHeight * 0.3);
            eye2 = Offset(x + cellWidth * 0.3, y + cellHeight * 0.7);
            break;
          case Direction.right:
            eye1 = Offset(x + cellWidth * 0.7, y + cellHeight * 0.3);
            eye2 = Offset(x + cellWidth * 0.7, y + cellHeight * 0.7);
            break;
        }

        canvas.drawCircle(eye1, eyeRadius, eyePaint);
        canvas.drawCircle(eye2, eyeRadius, eyePaint);
      } else {
        // Draw Body Segment with smooth rounded shape & gradient transition
        double progress = i / snake.length;
        
        // Let's create a tail color slightly darker/different
        HSLColor hsl = HSLColor.fromColor(baseSnakeColor);
        Color tailColor = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
        Color bodyColor = Color.lerp(baseSnakeColor, tailColor, progress) ?? tailColor;

        final bodyPaint = Paint()
          ..color = bodyColor
          ..style = PaintingStyle.fill;

        final double margin = 1.5;
        final rect = Rect.fromLTWH(
          x + margin,
          y + margin,
          cellWidth - (margin * 2),
          cellHeight - (margin * 2),
        );

        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cellWidth * 0.3)), bodyPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnakeGamePainter oldDelegate) {
    // Always repaint when ListenableBuilder triggers so snake movement & eyes update in 0ms
    return true;
  }
}
