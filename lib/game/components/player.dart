import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/types.dart';
import '../magma_game.dart';
import 'platform.dart';

class Player extends PositionComponent with HasGameRef<MagmaGame> {
  double vx = 0;
  double vy = 0;
  bool isGrounded = false;
  bool isRocketing = false;
  double rocketDistance = 0;

  bool leftPressed = false;
  bool rightPressed = false;

  final Paint _paintPlayer = Paint()
    ..color = AppColors.player
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
    
  final Paint _paintRocketFlame = Paint()..color = AppColors.rocketFlame;
  final Paint _paintRocketCore = Paint()..color = const Color(0xFFfbbf24);

  double _animTime = 0;

  Player() {
    size = Vector2(30, 50);
    position = Vector2(GameConstants.gameWidth / 2 - 15, GameConstants.gameHeight - 150);
    priority = 10;
  }

  void jump() {
    if (isGrounded && !isRocketing) {
      vy = Physics.jumpForce;
      isGrounded = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;

    if (isRocketing) {
      vy = -PlatformConfig.rocketSpeed;
      vx = 0;
      double moveStep = vy * (dt * 60); 
      y += moveStep;
      rocketDistance -= moveStep.abs();

      if (rocketDistance <= 0) {
        isRocketing = false;
        vy = -5;
      }
    } else {
      // FIX: Giảm gia tốc xuống 0.25 cho di chuyển mượt và chính xác
      if (leftPressed) vx -= 0.25;
      else if (rightPressed) vx += 0.25;
      else vx *= Physics.friction;

      vx = vx.clamp(-Physics.moveSpeed, Physics.moveSpeed);
      vy += Physics.gravity;

      x += vx * (dt * 60);
      y += vy * (dt * 60);
    }

    if (x < 0) x = 0;
    if (x + width > GameConstants.gameWidth) x = GameConstants.gameWidth - width;

    // --- LOGIC VA CHẠM (GIỮ NGUYÊN) ---
    if (!isRocketing) {
      isGrounded = false;
      for (final platform in gameRef.world.children.whereType<Platform>()) {
        final platData = platform.data;

        if (vy > 0 &&
            x + width > platData.x &&
            x < platData.x + platData.w &&
            y + height >= platData.y &&
            y + height <= platData.y + platData.h + (vy * dt * 60)) {
          
          y = platData.y - height;
          vy = 0;
          isGrounded = true;
          if (platData.dx != 0) x += platData.dx;
        }

        const boxSize = 24.0;
        final bx = platData.x + (platData.w / 2) - (boxSize / 2);
        final by = platData.y - boxSize;

        bool checkOverlap() {
          return x < bx + boxSize && x + width > bx && y < by + boxSize && y + height > by;
        }

        if (platData.hasLuckyBox && !platData.luckyBoxCollected) {
          if (checkOverlap()) {
            platData.luckyBoxCollected = true;
            _activateRocket();
          }
        }

        if (platData.hasUnluckyBox && !platData.unluckyBoxCollected) {
           if (checkOverlap()) {
            platData.unluckyBoxCollected = true;
            gameRef.gameOver();
            return;
          }
        }
      }
    }
  }

  void _activateRocket() {
    isRocketing = true;
    rocketDistance = PlatformConfig.rocketBoostDistance;
    gameRef.pushLavaBack();
  }

  @override
  void render(Canvas canvas) {
    if (isRocketing) {
      final flameX = width / 2;
      final flameY = height;
      final path = Path();
      path.moveTo(flameX - 10, flameY);
      path.lineTo(flameX + 10, flameY);
      path.lineTo(flameX, flameY + 30 + Random().nextDouble() * 20);
      canvas.drawPath(path, _paintRocketFlame);

      final pathCore = Path();
      pathCore.moveTo(flameX - 6, flameY);
      pathCore.lineTo(flameX + 6, flameY);
      pathCore.lineTo(flameX, flameY + 15 + Random().nextDouble() * 10);
      canvas.drawPath(pathCore, _paintRocketCore);
    }

    final cx = width / 2;
    final cy = 10.0;
    canvas.drawCircle(Offset(cx, cy), 8, _paintPlayer);
    canvas.drawLine(Offset(cx, cy + 8), Offset(cx, cy + 28), _paintPlayer);
    final armY = cy + 12;
    double armSwing = 5;
    if (vy < 0) armSwing = -12; 
    else if (isRocketing) armSwing = -15;
    else if (vx.abs() > 0.5) armSwing = sin(_animTime * 10) * 12;

    Path leftArm = Path()..moveTo(cx, armY)..lineTo(cx - 15, armY + armSwing);
    canvas.drawPath(leftArm, _paintPlayer);
    Path rightArm = Path()..moveTo(cx, armY)..lineTo(cx + 15, armY - armSwing);
    canvas.drawPath(rightArm, _paintPlayer);

    final legY = cy + 28;
    double walk = 5;
    if (isRocketing) walk = 3;
    else if (vx.abs() > 0.5) walk = sin(_animTime * 12) * 14;

    Path legs = Path();
    legs.moveTo(cx, legY);
    legs.lineTo(cx - walk, height); 
    legs.moveTo(cx, legY);
    legs.lineTo(cx + walk, height);
    canvas.drawPath(legs, _paintPlayer);
  }
}