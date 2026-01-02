import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/types.dart';
import 'components/platform.dart';
import 'components/player.dart';

class MagmaGame extends FlameGame with TapCallbacks {
  Player? player;
  List<Platform> platforms = []; 
  double lavaLevel = 0;
  
  GameState gameState = GameState.start;
  int score = 0;
  Function(int) onScoreChanged;
  Function(int) onGameOver;

  late final JoystickComponent joystick;

  // QUẢN LÝ MÀU JOYSTICK ĐỂ ẨN/HIỆN
  final Paint knobPaint = Paint()..color = Colors.white.withOpacity(0.5);
  final Paint backgroundPaint = Paint()..color = Colors.white.withOpacity(0.1);

  MagmaGame({
    required this.onScoreChanged, 
    required this.onGameOver
  });

  @override
  Color backgroundColor() => AppColors.bg;

  @override
  Future<void> onLoad() async {
    // --- FIX QUAN TRỌNG: FIXED RESOLUTION ---
    // Ép game chạy ở độ phân giải thiết kế (450x800) bất kể màn hình thiết bị
    // Nó sẽ tự phóng to trên iPad để vừa khít chiều cao
    camera = CameraComponent.withFixedResolution(
      width: GameConstants.gameWidth,
      height: GameConstants.gameHeight,
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    // --- SETUP JOYSTICK ---
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 25, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
      priority: 100, 
    );
    
    // Joystick sẽ được add vào Viewport ảo (450x800), nên vị trí sẽ luôn chuẩn
    camera.viewport.add(joystick);
    
    // Mặc định ẩn
    _setJoystickVisible(false);
  }

  void _setJoystickVisible(bool visible) {
    if (visible) {
      knobPaint.color = Colors.white.withOpacity(0.5);
      backgroundPaint.color = Colors.white.withOpacity(0.1);
    } else {
      knobPaint.color = Colors.transparent;
      backgroundPaint.color = Colors.transparent;
    }
  }

  void resetGame() {
    world.children.whereType<Platform>().forEach((p) => p.removeFromParent());
    if (player != null && player!.isMounted) player!.removeFromParent();
    platforms.clear();

    player = Player();
    world.add(player!);

    _spawnInitialPlatforms();

    score = 0;
    onScoreChanged(0);
    lavaLevel = GameConstants.gameHeight + 200;
    
    // Reset camera về 0
    camera.viewfinder.position = Vector2.zero();

    gameState = GameState.playing;

    _setJoystickVisible(true);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == GameState.playing && player != null) {
      // Chuyển toạ độ tap từ màn hình thật sang màn hình ảo
      final viewPos = camera.viewport.globalToLocal(event.localPosition);
      
      if (!joystick.containsPoint(viewPos)) {
        player!.jump();
      }
    }
  }

  void _spawnInitialPlatforms() {
    _addPlatform(PlatformData(x: 0, y: GameConstants.gameHeight - 50, w: GameConstants.gameWidth, h: 50));
    double nextY = GameConstants.gameHeight - 220;
    double lastX = GameConstants.gameWidth / 2 - 55;
    for (int i = 0; i < 15; i++) {
      final platData = _createPlatformData(nextY, lastX);
      _addPlatform(platData);
      lastX = platData.x;
      nextY -= PlatformConfig.spawnInterval;
    }
  }

  PlatformData _createPlatformData(double y, double lastX) {
    double x = lastX + (Random().nextDouble() - 0.5) * PlatformConfig.maxXDiff * 2;
    x = max(20, min(GameConstants.gameWidth - 130, x));
    bool isMoving = Random().nextDouble() < PlatformConfig.moveChance;
    double dx = 0;
    if (isMoving) {
      dx = (PlatformConfig.minSpeed + Random().nextDouble() * (PlatformConfig.maxSpeed - PlatformConfig.minSpeed));
      if (Random().nextBool()) dx *= -1;
    }
    bool hasLucky = false;
    bool hasUnlucky = false;
    double rand = Random().nextDouble();
    if (y < GameConstants.gameHeight - 300) {
      if (rand < PlatformConfig.luckyBoxChance) {
        hasLucky = true;
      } else if (rand < PlatformConfig.luckyBoxChance + PlatformConfig.unluckyBoxChance) {
        hasUnlucky = true;
      }
    }
    return PlatformData(x: x, y: y, w: PlatformConfig.width, h: PlatformConfig.height, dx: dx, hasLuckyBox: hasLucky, hasUnluckyBox: hasUnlucky);
  }

  void _addPlatform(PlatformData data) {
    final p = Platform(data: data);
    platforms.add(p);
    world.add(p);
    if (platforms.length > 60) {
      final old = platforms.removeAt(0);
      old.removeFromParent();
    }
  }

  void pushLavaBack() {
    lavaLevel += PlatformConfig.lavaPushBack;
  }

  void gameOver() {
    if (gameState == GameState.playing) {
      gameState = GameState.gameOver;
      
      _setJoystickVisible(false);

      pauseEngine(); 
      onGameOver(score);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameState != GameState.playing || player == null) return;

    final p = player!;

    // --- INPUT JOYSTICK ---
    p.leftPressed = false;
    p.rightPressed = false;

    if (joystick.relativeDelta.x < -0.2) { 
      p.leftPressed = true;
    } else if (joystick.relativeDelta.x > 0.2) {
      p.rightPressed = true;
    }

    // --- SMOOTH CAMERA ---
    double targetCamY = p.y - (GameConstants.gameHeight * 0.55); 
    if (targetCamY > 0) targetCamY = 0;
    double currentY = camera.viewfinder.position.y;
    double newY = lerpDouble(currentY, targetCamY, dt * 3.0) ?? currentY;
    if (p.isRocketing) {
       newY = lerpDouble(currentY, targetCamY, dt * 10.0) ?? currentY;
    }
    camera.viewfinder.position = Vector2(0, newY);

    // --- LOGIC MAP ---
    if (platforms.isNotEmpty) {
      final topPlat = platforms.last;
      if (topPlat.y > camera.viewfinder.position.y - 800) {
         final newData = _createPlatformData(topPlat.data.y - PlatformConfig.spawnInterval, topPlat.data.x);
         _addPlatform(newData);
      }
    }

    lavaLevel -= Physics.lavaSpeed * (dt * 60);
    if (p.y + p.height > lavaLevel && !p.isRocketing) {
      gameOver();
    }

    int currentHeight = ((GameConstants.gameHeight - 120 - p.y) / 20).floor();
    if (currentHeight > score) {
      score = currentHeight;
      onScoreChanged(score);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (gameState != GameState.playing) return;
    
    final paintLava = Paint()..color = AppColors.lava;
    final path = Path();
    double waveOffset = (DateTime.now().millisecondsSinceEpoch / 500);
    double screenLavaY = lavaLevel - camera.viewfinder.position.y;

    path.moveTo(0, screenLavaY);
    for (double i = 0; i <= GameConstants.gameWidth; i += 20) {
      double wave = sin(waveOffset + (i / 50)) * 5;
      path.lineTo(i, screenLavaY + wave);
    }
    path.lineTo(GameConstants.gameWidth, screenLavaY + 2000);
    path.lineTo(0, screenLavaY + 2000);
    path.close();
    
    canvas.drawPath(path, paintLava);
  }
}