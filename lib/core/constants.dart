import 'dart:ui';

class GameConstants {
  static const double gameWidth = 450;
  static const double gameHeight = 800;
}

class Physics {
  static const double gravity = 0.5;
  static const double jumpForce = -19.0;
  static const double moveSpeed = 7.0;
  static const double friction = 0.8;
  static const double airResistance = 0.96;
  static const double lavaSpeed = 0.8;
}

class PlatformConfig {
  static const double width = 110.0;
  static const double height = 18.0;
  static const double spawnInterval = 160.0;
  static const double maxXDiff = 180.0;
  static const double moveChance = 0.75;
  static const double minSpeed = 1.2;
  static const double maxSpeed = 4.0;
  static const double luckyBoxChance = 0.12;
  static const double unluckyBoxChance = 0.08;
  static const double lavaPushBack = 200.0;
  static const double rocketBoostDistance = 2000.0;
  static const double rocketSpeed = 15.0;
}

class AppColors {
  // Web: #0a0a0c -> Flutter: 0xFF0a0a0c
  static const Color bg = Color(0xFF0a0a0c);
  static const Color platform = Color(0xFF1e1e24);
  static const Color platformTop = Color(0xFF6366f1);
  static const Color player = Color(0xFFFFFFFF);
  static const Color lava = Color(0xFFef4444);
  
  static const Color luckyBox = Color(0xFFfbbf24);
  static const Color luckyBoxGlow = Color(0xFFf59e0b);
  
  static const Color unluckyBox = Color(0xFF991b1b);
  static const Color unluckyBoxGlow = Color(0xFFef4444);
  
  static const Color rocketFlame = Color(0xFFf97316);
}