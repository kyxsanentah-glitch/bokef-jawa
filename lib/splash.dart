import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const SplashScreen({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
    required this.listDoos,
    required this.news,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  bool _fadeOutStarted = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset("assets/videos/splash.mp4")
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(false);
        _videoController.play();

        _fadeController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 1),
        );

        _videoController.addListener(() {
          final position = _videoController.value.position;
          final duration = _videoController.value.duration;

          if (duration != null &&
              position >= duration - const Duration(seconds: 1) &&
              !_fadeOutStarted) {
            _fadeOutStarted = true;
            _fadeController.forward();
          }

          if (position >= duration) {
            _navigateToDashboard();
          }
        });
      });
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          username: widget.username,
          password: widget.password,
          role: widget.role,
          expiredDate: widget.expiredDate,
          sessionKey: widget.sessionKey,
          listBug: widget.listBug,
          listDoos: widget.listDoos,
          news: widget.news,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (_videoController.value.isInitialized)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          Positioned(
            bottom: 80,
            child: Text(
              "SaturnX System",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: Colors.pinkAccent.withOpacity(0.9),
                    blurRadius: 10,
                    offset: const Offset(2, 2),
                  ),
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 15,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
            ),
          ),

          if (_fadeOutStarted)
            FadeTransition(
              opacity: _fadeController.drive(Tween(begin: 1.0, end: 0.0)),
              child: Container(color: Colors.black),
            ),
        ],
      ),
    );
  }
}