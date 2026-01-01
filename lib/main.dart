import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'core/types.dart';
import 'game/magma_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MagmaApp(),
  ));
}

class MagmaApp extends StatefulWidget {
  const MagmaApp({super.key});

  @override
  State<MagmaApp> createState() => _MagmaAppState();
}

class _MagmaAppState extends State<MagmaApp> {
  late MagmaGame _game;
  int _score = 0;
  int _highScore = 0;
  GameState _uiState = GameState.start;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    
    _game = MagmaGame(
      onScoreChanged: (newScore) {
        if (_score != newScore) {
          // FIX LỖI 1: Bọc setState để tránh xung đột lúc build
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _score = newScore;
              });
            });
          }
        }
      },
      onGameOver: (finalScore) {
        // FIX LỖI 1
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleGameOver(finalScore);
          });
        }
      },
    );
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('magma_best') ?? 0;
    });
  }

  Future<void> _handleGameOver(int score) async {
    setState(() {
      _score = score;
      _uiState = GameState.gameOver;
    });

    if (score > _highScore) {
      _highScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('magma_best', score);
    }
  }

  void _startGame() {
    setState(() {
      _uiState = GameState.playing;
      _score = 0;
    });
    _game.resetGame();
    _game.resumeEngine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // LAYER 1: The Game
          GameWidget(game: _game),

          // LAYER 2: HUD (Điểm số) - Controls đã chuyển vào trong GameWidget
          if (_uiState == GameState.playing)
            _buildHUD(),

          // LAYER 3: Menu Screens
          if (_uiState == GameState.start)
            _buildStartScreen(),

          if (_uiState == GameState.gameOver)
            _buildGameOverScreen(),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHudCircle('ALT', '$_score', Colors.orange),
            _buildHudCircle('TOP', '$_highScore', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildHudCircle(String label, String value, Color color) {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          Text(value + 'm', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Container(
      color: const Color(0xFFf0f0f0).withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(scale: 1.2),
            const SizedBox(height: 30),
            Text("A hand-drawn ascent above the rising lava.\nAvoid the void.", textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _startGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(color: AppColors.platformTop, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.platformTop.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]),
                child: Text("START CHALLENGE", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverScreen() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(opacity: 0.5, child: _buildLogo(scale: 0.6)),
            const SizedBox(height: 20),
            Text("BURNED", style: GoogleFonts.inter(color: AppColors.lava, fontSize: 60, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            const Text("THE MAGMA CLAIMED ANOTHER SOUL", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 3)),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScoreBox("SCORE", "$_score", Colors.white),
                const SizedBox(width: 20),
                _buildScoreBox("RECORD", "$_highScore", Colors.orange),
              ],
            ),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: _startGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20)]),
                child: Text("TRY AGAIN", style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo({double scale = 1.0}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        decoration: BoxDecoration(border: Border.all(color: Colors.indigo.withOpacity(0.6), width: 2), borderRadius: BorderRadius.circular(20), color: Colors.white.withOpacity(0.1)),
        child: Text("magma", style: GoogleFonts.orbitron(fontSize: 40, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.transparent, shadows: [const Shadow(offset: Offset(-1.5, -1.5), color: Colors.indigo), const Shadow(offset: Offset(1.5, -1.5), color: Colors.indigo), const Shadow(offset: Offset(1.5, 1.5), color: Colors.indigo), const Shadow(offset: Offset(-1.5, 1.5), color: Colors.indigo)])),
      ),
    );
  }

  Widget _buildScoreBox(String label, String value, Color color) {
    return Container(
      width: 100, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[800]!)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value + 'm', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}