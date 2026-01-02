import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';

class Lava extends PositionComponent {
  final Paint _paintLava = Paint()..color = AppColors.lava;
  double _time = 0;

  Lava() {
    // Kích thước Lava bao trùm chiều ngang game
    // Vẽ dư ra 2 bên một chút (-100 đến width + 100) để tránh bị hở mép khi màn hình rung lắc
    size = Vector2(GameConstants.gameWidth, 2000); 
    priority = 2; // Vẽ đè lên background nhưng dưới Player (hoặc trên tuỳ bạn)
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final path = Path();
    
    // Tạo hiệu ứng sóng
    // Lưu ý: Vẽ bắt đầu từ y = 0 (tức là ngay tại vị trí this.y của component)
    double waveOffset = (_time * 2); // Tốc độ sóng

    path.moveTo(-100, 0); // Bắt đầu từ bên trái màn hình (vẽ dư ra)
    
    // Vẽ sóng ngang qua màn hình
    for (double i = -100; i <= GameConstants.gameWidth + 100; i += 20) {
      double wave = sin(waveOffset + (i / 50)) * 10;
      path.lineTo(i, wave);
    }

    // Vẽ phần thân Lava kéo dài xuống dưới
    path.lineTo(GameConstants.gameWidth + 100, size.y);
    path.lineTo(-100, size.y);
    path.close();

    canvas.drawPath(path, _paintLava);
  }
}