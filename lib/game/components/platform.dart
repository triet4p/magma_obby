import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/types.dart';

class Platform extends PositionComponent {
  final PlatformData data;

  // Dùng Paint để tối ưu hiệu năng, tránh tạo mới trong vòng lặp render
  final Paint _paintPlatform = Paint()..color = AppColors.platform;
  final Paint _paintTop = Paint()..color = AppColors.platformTop;
  final Paint _paintMovingTrail = Paint()..color = Colors.white.withOpacity(0.1);
  
  // Box Paints
  final Paint _paintLucky = Paint()..color = AppColors.luckyBox;
  final Paint _paintUnlucky = Paint()..color = AppColors.unluckyBox;
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  double _time = 0; // Để làm hiệu ứng glow animation

  Platform({required this.data}) {
    position = Vector2(data.x, data.y);
    size = Vector2(data.w, data.h);
    priority = 1; // Vẽ sau background
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Logic di chuyển platform ngang
    if (data.dx != 0) {
      x += data.dx;
      // Cập nhật lại data gốc để đồng bộ
      data.x = x; 

      // Va chạm tường trái phải
      if (x <= 0 || x + width >= GameConstants.gameWidth) {
        data.dx *= -1;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. Vẽ thân Platform
    canvas.drawRect(size.toRect(), _paintPlatform);

    // 2. Vẽ mặt trên (Top strip)
    canvas.drawRect(Rect.fromLTWH(0, 0, width, 3), _paintTop);

    // 3. Hiệu ứng khi di chuyển (Trail)
    if (data.dx != 0) {
      canvas.drawRect(Rect.fromLTWH(0, 5, width, 2), _paintMovingTrail);
    }

    // 4. Vẽ Box (Nếu có và chưa ăn)
    _drawBox(canvas, isLucky: true);
    _drawBox(canvas, isLucky: false);
  }

  void _drawBox(Canvas canvas, {required bool isLucky}) {
    final hasBox = isLucky ? data.hasLuckyBox : data.hasUnluckyBox;
    final collected = isLucky ? data.luckyBoxCollected : data.unluckyBoxCollected;

    if (hasBox && !collected) {
      const boxSize = 24.0;
      final bx = (width / 2) - (boxSize / 2);
      final by = -boxSize; // Vẽ nằm trên platform

      // Hiệu ứng Glow (Shadow) mô phỏng code JS: Math.sin(...)
      final glowIntensity = sin(_time * (isLucky ? 5 : 10)) * (isLucky ? 4 : 5) + 8;
      
      final paint = isLucky ? _paintLucky : _paintUnlucky;
      final glowColor = isLucky ? AppColors.luckyBoxGlow : AppColors.unluckyBoxGlow;

      // Vẽ Glow (Shadow)
      final path = Path()..addRect(Rect.fromLTWH(bx, by, boxSize, boxSize));
      canvas.drawShadow(path, glowColor, glowIntensity, true);

      // Vẽ Box
      canvas.drawRect(Rect.fromLTWH(bx, by, boxSize, boxSize), paint);

      // Vẽ dấu chấm hỏi "?"
      _textPainter.text = const TextSpan(
        text: '?',
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      if (!isLucky) {
        _textPainter.text = const TextSpan(
          text: '?',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        );
      }
      _textPainter.layout();
      _textPainter.paint(
        canvas,
        Offset(bx + (boxSize - _textPainter.width) / 2, by + (boxSize - _textPainter.height) / 2),
      );
    }
  }
}