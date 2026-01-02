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
import 'components/lava.dart'; // <-- NHỚ IMPORT FILE LAVA MỚI

class MagmaGame extends FlameGame with TapCallbacks {
  Player? player;
  // Thêm Component Lava
  late final Lava lava;
  
  List<Platform> platforms = []; 
  double lavaLevel = 0;
  
  GameState gameState = GameState.start;
  int score = 0;
  Function(int) onScoreChanged;
  Function(int) onGameOver;

  late final JoystickComponent joystick;
  
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
    // Camera Fixed Resolution: Tự động scale game để vừa khít màn hình iPad
    camera = CameraComponent.withFixedResolution(
      width: GameConstants.gameWidth,
      height: GameConstants.gameHeight,
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    // 1. Khởi tạo Lava
    lava = Lava();
    
    // 2. Setup Joystick
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 25, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
      priority: 100, 
    );
    
    camera.viewport.add(joystick);
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
    
    // Nếu lava chưa add vào world thì add, nếu có rồi thì thôi
    if (!lava.isMounted) world.add(lava);

    platforms.clear();

    player = Player();
    world.add(player!);

    _spawnInitialPlatforms();

    score = 0;
    onScoreChanged(0);
    
    // Reset vị trí Lava
    lavaLevel = GameConstants.gameHeight + 200;
    lava.position = Vector2(0, lavaLevel); // Cập nhật vị trí hiển thị ngay

    camera.viewfinder.position = Vector2.zero();

    gameState = GameState.playing;
    _setJoystickVisible(true);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == GameState.playing && player != null) {
      final viewPos = camera.viewport.globalToLocal(event.localPosition);
      if (!joystick.containsPoint(viewPos)) {
        player!.jump();
      }
    }
  }

  // --- SPAWN LOGIC (Giữ nguyên) ---
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

    // Input & Camera Logic (Giữ nguyên)
    p.leftPressed = false;
    p.rightPressed = false;
    if (joystick.relativeDelta.x < -0.2) p.leftPressed = true;
    else if (joystick.relativeDelta.x > 0.2) p.rightPressed = true;

    double targetCamY = p.y - (GameConstants.gameHeight * 0.55); 
    if (targetCamY > 0) targetCamY = 0;
    double currentY = camera.viewfinder.position.y;
    double newY = lerpDouble(currentY, targetCamY, dt * 3.0) ?? currentY;
    if (p.isRocketing) newY = lerpDouble(currentY, targetCamY, dt * 10.0) ?? currentY;
    camera.viewfinder.position = Vector2(0, newY);

    if (platforms.isNotEmpty) {
      final topPlat = platforms.last;
      if (topPlat.y > camera.viewfinder.position.y - 800) {
         final newData = _createPlatformData(topPlat.data.y - PlatformConfig.spawnInterval, topPlat.data.x);
         _addPlatform(newData);
      }
    }

    // --- LAVA LOGIC MỚI ---
    // 1. Tính toán mực nước
    lavaLevel -= Physics.lavaSpeed * (dt * 60);
    
    // 2. Cập nhật vị trí hiển thị của Component Lava (ĐỒNG BỘ VISUAL)
    lava.position = Vector2(0, lavaLevel);

    // 3. Kiểm tra va chạm (ĐỒNG BỘ LOGIC)
    // Lưu ý: +10 để du di một chút cho người chơi
    if (p.y + p.height > lavaLevel + 10 && !p.isRocketing) {
      gameOver();
    }

    int currentHeight = ((GameConstants.gameHeight - 120 - p.y) / 20).floor();
    if (currentHeight > score) {
      score = currentHeight;
      onScoreChanged(score);
    }
  }

  // --- ĐÃ XÓA HÀM RENDER THỦ CÔNG ---
  // Lava giờ tự vẽ chính nó thông qua Lava Component
}