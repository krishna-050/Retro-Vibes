import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

enum Direction { up, down, left, right }

enum CollectibleType { note, cassette, vinyl }

enum SnakeColorOption { classicGreen, retroYellow, red, blue, purple, orange, cyan, pink, white }

extension SnakeColorOptionExtension on SnakeColorOption {
  Color get color {
    switch (this) {
      case SnakeColorOption.classicGreen: return const Color(0xFF00FF66);
      case SnakeColorOption.retroYellow: return AppTheme.yellow300;
      case SnakeColorOption.red: return Colors.redAccent;
      case SnakeColorOption.blue: return Colors.blueAccent;
      case SnakeColorOption.purple: return Colors.purpleAccent;
      case SnakeColorOption.orange: return Colors.orangeAccent;
      case SnakeColorOption.cyan: return Colors.cyanAccent;
      case SnakeColorOption.pink: return Colors.pinkAccent;
      case SnakeColorOption.white: return Colors.white;
    }
  }

  String get name {
    switch (this) {
      case SnakeColorOption.classicGreen: return 'Classic Green';
      case SnakeColorOption.retroYellow: return 'Retro Yellow';
      case SnakeColorOption.red: return 'Red';
      case SnakeColorOption.blue: return 'Blue';
      case SnakeColorOption.purple: return 'Purple';
      case SnakeColorOption.orange: return 'Orange';
      case SnakeColorOption.cyan: return 'Cyan';
      case SnakeColorOption.pink: return 'Pink';
      case SnakeColorOption.white: return 'White';
    }
  }
}

enum StartingSpeed { slow, normal, fast, veryFast }

extension StartingSpeedExtension on StartingSpeed {
  int get msInterval {
    switch (this) {
      case StartingSpeed.slow: return 180;
      case StartingSpeed.normal: return 140;
      case StartingSpeed.fast: return 100;
      case StartingSpeed.veryFast: return 70;
    }
  }

  String get name {
    switch (this) {
      case StartingSpeed.slow: return 'Slow';
      case StartingSpeed.normal: return 'Normal';
      case StartingSpeed.fast: return 'Fast';
      case StartingSpeed.veryFast: return 'Very Fast';
    }
  }
}

class Collectible {
  final Point<int> position;
  final CollectibleType type;

  Collectible({required this.position, required this.type});

  int get points {
    switch (type) {
      case CollectibleType.note:
        return 10;
      case CollectibleType.cassette:
        return 20;
      case CollectibleType.vinyl:
        return 30;
    }
  }
}

class RetroSnakeGame extends ChangeNotifier {
  static const int cols = 20;
  static const int rows = 25;

  SharedPreferences? _prefs;

  SnakeColorOption _snakeColor = SnakeColorOption.retroYellow;
  StartingSpeed _startingSpeed = StartingSpeed.normal;

  List<Point<int>> _snake = [
    const Point(10, 12),
    const Point(10, 13),
    const Point(10, 14),
  ];

  Direction _currentDirection = Direction.up;
  Direction _nextDirection = Direction.up;
  final List<Direction> _inputQueue = [];

  Collectible? _collectible;
  bool _isGameOver = false;
  bool _isPaused = false;
  bool _isNewHighScore = false;

  int _score = 0;
  int _bestScore = 0;
  int _level = 1;

  Timer? _gameTimer;
  int _speedMs = 140;

  List<Point<int>> get snake => _snake;
  Collectible? get collectible => _collectible;
  Direction get currentDirection => _nextDirection;
  bool get isGameOver => _isGameOver;
  bool get isPaused => _isPaused;
  bool get isNewHighScore => _isNewHighScore;
  int get score => _score;
  int get bestScore => _bestScore;
  int get level => _level;
  
  SnakeColorOption get snakeColor => _snakeColor;
  StartingSpeed get startingSpeed => _startingSpeed;

  RetroSnakeGame() {
    _initPrefsAndStart();
  }

  Future<void> _initPrefsAndStart() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _bestScore = _prefs?.getInt('retro_snake_best_score') ?? 0;
      
      int colorIndex = _prefs?.getInt('retro_snake_color') ?? SnakeColorOption.retroYellow.index;
      _snakeColor = SnakeColorOption.values.firstWhere((e) => e.index == colorIndex, orElse: () => SnakeColorOption.retroYellow);
      
      int speedIndex = _prefs?.getInt('retro_snake_speed') ?? StartingSpeed.normal.index;
      _startingSpeed = StartingSpeed.values.firstWhere((e) => e.index == speedIndex, orElse: () => StartingSpeed.normal);
    } catch (_) {}
    startGame();
  }

  void updateSettings(SnakeColorOption color, StartingSpeed speed) {
    _snakeColor = color;
    _startingSpeed = speed;
    _prefs?.setInt('retro_snake_color', color.index);
    _prefs?.setInt('retro_snake_speed', speed.index);
    notifyListeners();
  }

  void startGame() {
    _gameTimer?.cancel();
    _inputQueue.clear();
    _snake = [
      const Point(10, 12),
      const Point(10, 13),
      const Point(10, 14),
    ];
    _currentDirection = Direction.up;
    _nextDirection = Direction.up;
    _score = 0;
    _level = 1;
    _speedMs = _startingSpeed.msInterval;
    _isGameOver = false;
    _isPaused = false;
    _isNewHighScore = false;
    _spawnCollectible();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(Duration(milliseconds: _speedMs), (_) {
      _updateGame();
    });
  }

  void changeDirection(Direction newDir) {
    if (_isPaused || _isGameOver) return;

    final Direction lastDir = _inputQueue.isNotEmpty ? _inputQueue.last : _currentDirection;

    // Prevent immediate 180-degree reverse
    if ((lastDir == Direction.up && newDir == Direction.down) ||
        (lastDir == Direction.down && newDir == Direction.up) ||
        (lastDir == Direction.left && newDir == Direction.right) ||
        (lastDir == Direction.right && newDir == Direction.left) ||
        lastDir == newDir) {
      return;
    }

    if (_inputQueue.length < 2) {
      _inputQueue.add(newDir);
    }
    _nextDirection = newDir;
    notifyListeners();
  }

  void togglePause() {
    if (_isGameOver) return;
    _isPaused = !_isPaused;
    if (_isPaused) {
      _gameTimer?.cancel();
    } else {
      _startTimer();
    }
    notifyListeners();
  }

  void pauseGame() {
    if (!_isPaused && !_isGameOver) {
      _isPaused = true;
      _gameTimer?.cancel();
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_isPaused && !_isGameOver) {
      _isPaused = false;
      _startTimer();
      notifyListeners();
    }
  }

  void _spawnCollectible() {
    final rand = Random();
    final snakeSet = _snake.toSet();
    Point<int> newPos;

    int attempts = 0;
    while (true) {
      attempts++;
      int x = rand.nextInt(cols);
      int y = rand.nextInt(rows);
      newPos = Point(x, y);

      if (!snakeSet.contains(newPos) || attempts > 200) {
        break;
      }
    }

    // Determine type (70% note, 20% cassette, 10% vinyl)
    int typeChance = rand.nextInt(100);
    CollectibleType type;
    if (typeChance < 70) {
      type = CollectibleType.note;
    } else if (typeChance < 90) {
      type = CollectibleType.cassette;
    } else {
      type = CollectibleType.vinyl;
    }

    _collectible = Collectible(position: newPos, type: type);
  }

  void _updateGame() {
    if (_isPaused || _isGameOver) return;

    if (_inputQueue.isNotEmpty) {
      _currentDirection = _inputQueue.removeAt(0);
      _nextDirection = _currentDirection;
    }

    Point<int> head = _snake.first;
    Point<int> newHead;

    switch (_currentDirection) {
      case Direction.up:
        newHead = Point(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Point(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Point(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Point(head.x + 1, head.y);
        break;
    }

    // Boundary check (Game Over on wall collision)
    if (newHead.x < 0 || newHead.x >= cols || newHead.y < 0 || newHead.y >= rows) {
      _gameOver();
      return;
    }

    // Self collision check
    if (_snake.contains(newHead)) {
      _gameOver();
      return;
    }

    _snake.insert(0, newHead);

    // Check collectible
    if (_collectible != null && newHead == _collectible!.position) {
      _score += _collectible!.points;
      if (_score > _bestScore) {
        _bestScore = _score;
        _isNewHighScore = true;
        _prefs?.setInt('retro_snake_best_score', _bestScore);
      }
      
      // Automatic speed increase logic
      int growth = _snake.length - 3;
      int speedIncrease = 2; // Decrease interval by 2ms per food eaten
      int safeMinimumMs = 60;
      int newSpeedMs = max(safeMinimumMs, _startingSpeed.msInterval - (growth * speedIncrease));
      
      if (newSpeedMs != _speedMs) {
        _speedMs = newSpeedMs;
        _startTimer();
      }

      _checkLevelUp();
      _spawnCollectible();
    } else {
      _snake.removeLast();
    }

    notifyListeners();
  }

  void _checkLevelUp() {
    int newLevel = 1 + (_score ~/ 50);
    if (newLevel != _level) {
      _level = newLevel;
    }
  }

  void _gameOver() {
    _isGameOver = true;
    _gameTimer?.cancel();
    if (_score > _bestScore) {
      _bestScore = _score;
      _isNewHighScore = true;
      _prefs?.setInt('retro_snake_best_score', _bestScore);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}
