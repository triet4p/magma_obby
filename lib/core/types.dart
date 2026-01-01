
enum GameState {
  start,
  playing,
  gameOver
}

class PlatformData {
  double x;
  double y;
  double w;
  double h;
  double dx; // Default 0
  
  bool hasLuckyBox;
  bool luckyBoxCollected;
  
  bool hasUnluckyBox;
  bool unluckyBoxCollected;

  PlatformData({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.dx = 0,
    this.hasLuckyBox = false,
    this.luckyBoxCollected = false,
    this.hasUnluckyBox = false,
    this.unluckyBoxCollected = false,
  });
}

class PlayerData {
  double x;
  double y;
  double vx;
  double vy;
  double w;
  double h;
  
  bool isGrounded;
  bool isRocketing;
  double rocketDistance;

  PlayerData({
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    required this.w,
    required this.h,
    this.isGrounded = false,
    this.isRocketing = false,
    this.rocketDistance = 0,
  });
}