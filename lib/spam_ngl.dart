import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class NglPage extends StatefulWidget {
  const NglPage({super.key});

  @override
  State<NglPage> createState() => _NglPageState();
}

class _NglPageState extends State<NglPage> with TickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isRunning = false;
  int counter = 0;
  String statusLog = "";
  Timer? timer;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

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

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
  }

  @override
  void dispose() {
    timer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String generateDeviceId(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  Future<void> sendMessage(String username, String message) async {
    final deviceId = generateDeviceId(42);
    final url = Uri.parse("https://ngl.link/api/submit");

    final headers = {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0",
      "Accept": "*/*",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "X-Requested-With": "XMLHttpRequest",
      "Referer": "https://ngl.link/$username",
      "Origin": "https://ngl.link"
    };

    final body =
        "username=$username&question=$message&deviceId=$deviceId&gameSlug=&referrer=";

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        setState(() {
          counter++;
          statusLog = "✅ [$counter] Pesan terkirim";
        });
        HapticFeedback.lightImpact();
      } else {
        setState(() {
          statusLog = "❌ Ratelimit (${response.statusCode}), tunggu 5 detik...";
        });
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      setState(() {
        statusLog = "⚠️ Error: $e";
      });
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void startLoop() {
    final username = usernameController.text.trim();
    final message = messageController.text.trim();

    if (username.isEmpty || message.isEmpty) {
      setState(() {
        statusLog = "⚠️ Harap isi username & pesan!";
      });
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      isRunning = true;
      counter = 0;
      statusLog = "▶️ Mulai mengirim...";
    });

    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isRunning) {
        sendMessage(username, message);
      }
    });
  }

  void stopLoop() {
    setState(() {
      isRunning = false;
      statusLog = "⏹️ Dihentikan.";
    });
    timer?.cancel();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: Stack(
        children: [
          _buildAnimatedBackground(),

          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNewHeader(),

                    const SizedBox(height: 20),

                    _buildNewInputSection(),

                    const SizedBox(height: 20),

                    _buildNewControlButtons(),

                    const SizedBox(height: 20),

                    _buildNewStatusSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _pulseController,
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
              ...List.generate(15, (index) {
                final top = (_pulseController.value + index * 0.07) % 1.0;
                final left = (index * 0.13) % 1.0;
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
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _pulseController.value * 2 * 3.14159,
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
                scale: isRunning ? _pulseAnimation.value : 1.0,
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
                    Icons.send,
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
                  "NGL AUTO SENDER",
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  "Automated Message System",
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
              color: isRunning ? Colors.greenAccent : Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isRunning ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5),
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

  Widget _buildNewInputSection() {
    return Container(
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
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: accentPink.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: usernameController,
              style: TextStyle(color: primaryWhite, fontSize: 16),
              decoration: InputDecoration(
                labelText: "Username NGL",
                labelStyle: TextStyle(color: lightPink),
                hintText: "contoh: username_ngl",
                hintStyle: TextStyle(color: accentGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                prefixIcon: Icon(Icons.person, color: lightPink),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: accentPink.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: messageController,
              style: TextStyle(color: primaryWhite, fontSize: 16),
              decoration: InputDecoration(
                labelText: "Pesan",
                labelStyle: TextStyle(color: lightPink),
                hintText: "Masukkan pesan yang ingin dikirim...",
                hintStyle: TextStyle(color: accentGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                prefixIcon: Icon(Icons.message, color: lightPink),
              ),
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewControlButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: isRunning ? null : startLoop,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: isRunning
                    ? LinearGradient(
                  colors: [Colors.grey.shade700, Colors.grey.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [primaryPink, accentPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: isRunning
                        ? Colors.transparent
                        : accentPink.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      color: primaryWhite,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "START",
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
        ),

        const SizedBox(width: 16),

        Expanded(
          child: GestureDetector(
            onTap: isRunning ? stopLoop : null,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: isRunning
                    ? LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [Colors.grey.shade700, Colors.grey.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: isRunning
                        ? Colors.red.withOpacity(0.4)
                        : Colors.transparent,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stop,
                      color: primaryWhite,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "STOP",
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
        ),
      ],
    );
  }

  Widget _buildNewStatusSection() {
    return Expanded(
      child: Container(
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
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryPink, accentPink],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryWhite),
                  const SizedBox(width: 12),
                  Text(
                    "STATUS LOG",
                    style: TextStyle(
                      color: primaryWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentPink.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLog.isEmpty ? "Menunggu perintah..." : statusLog,
                        style: TextStyle(
                          color: _getStatusColor(statusLog),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (counter > 0)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryPink.withOpacity(0.2),
                      accentPink.withOpacity(0.1),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentPink.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, color: lightPink),
                    const SizedBox(width: 12),
                    Text(
                      "Total terkirim: ",
                      style: TextStyle(
                        color: lightPink,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "$counter",
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              margin: EdgeInsets.only(top: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
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
                      "Auto send setiap 2 detik. Stop manual jika sudah cukup.",
                      style: TextStyle(
                        color: accentGrey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('✅')) return Colors.greenAccent;
    if (status.contains('❌')) return Colors.redAccent;
    if (status.contains('⚠️')) return Colors.orangeAccent;
    if (status.contains('▶️')) return Colors.greenAccent;
    if (status.contains('⏹️')) return Colors.orangeAccent;
    return primaryWhite;
  }
}