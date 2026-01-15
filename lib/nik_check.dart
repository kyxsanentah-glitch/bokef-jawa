import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class NikCheckerPage extends StatefulWidget {
  const NikCheckerPage({super.key});

  @override
  State<NikCheckerPage> createState() => _NikCheckerPageState();
}

class _NikCheckerPageState extends State<NikCheckerPage> with TickerProviderStateMixin {
  final TextEditingController _nikController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _data;
  String? _errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final Color primaryDark = const Color(0xFF270A1A);
  final Color primaryPink = const Color(0xFF8A1E5A);
  final Color accentPink = const Color(0xFFF63B82);
  final Color lightPink = const Color(0xFFFA60A5);
  final Color cardDark = const Color(0xFF321529);
  final Color cardDarker = const Color(0xFF300F1F);
  final Color successGreen = const Color(0xFF10B981);
  final Color warningOrange = const Color(0xFFF59E0B);
  final Color dangerRed = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  Future<void> _checkNik() async {
    final nik = _nikController.text.trim();
    if (nik.isEmpty) {
      setState(() {
        _errorMessage = "NIK tidak boleh kosong.";
        _data = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _data = null;
    });

    final url = Uri.parse("https://api.siputzx.my.id/api/tools/nik-checker?nik=$nik");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          setState(() {
            _data = json['data'];
            _errorMessage = null;
          });
          _fadeController.reset();
          _fadeController.forward();
        } else {
          setState(() {
            _errorMessage = "Data tidak ditemukan atau NIK tidak valid.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data dari server.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDarker,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: successGreen.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: successGreen.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: successGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Copied!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$label disalin ke clipboard',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentPink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.credit_card,
                color: accentPink,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "NIK Checker",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [primaryPink, accentPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentPink.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.credit_card,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "NIK Verification",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Check Indonesian identity card information",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Enter NIK Number",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: cardDarker,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentPink.withOpacity(0.3)),
                        ),
                        child: TextField(
                          controller: _nikController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'e.g. 5206085405880001',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: _isLoading
                                ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: accentPink,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                                : null,
                          ),
                          onSubmitted: (_) => _checkNik(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [accentPink, lightPink],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentPink.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _checkNik,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "PROCESSING...",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "VERIFY NIK",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dangerRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dangerRed.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: dangerRed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                if (_data != null)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildInfoCard(
                          title: "Personal Information",
                          icon: Icons.person,
                          color: accentPink,
                          children: [
                            _buildInfoItem(
                              label: "NIK",
                              value: _data!["nik"]?.toString(),
                              showCopy: true,
                            ),
                            _buildInfoItem(
                              label: "Full Name",
                              value: _data!["data"]["nama"]?.toString(),
                              showCopy: true,
                            ),
                            _buildInfoItem(
                              label: "Gender",
                              value: _data!["data"]["kelamin"]?.toString(),
                            ),
                            _buildInfoItem(
                              label: "Birth Place",
                              value: _data!["data"]["tempat_lahir"]?.toString(),
                              showCopy: true,
                            ),
                            _buildInfoItem(
                              label: "Age",
                              value: _data!["data"]["usia"]?.toString(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildInfoCard(
                          title: "Address Information",
                          icon: Icons.location_on,
                          color: successGreen,
                          children: [
                            _buildInfoItem(
                              label: "Province",
                              value: _data!["data"]["provinsi"]?.toString(),
                            ),
                            _buildInfoItem(
                              label: "Regency/City",
                              value: _data!["data"]["kabupaten"]?.toString(),
                            ),
                            _buildInfoItem(
                              label: "District",
                              value: _data!["data"]["kecamatan"]?.toString(),
                            ),
                            _buildInfoItem(
                              label: "Sub-district/Village",
                              value: _data!["data"]["kelurahan"]?.toString(),
                            ),
                            _buildInfoItem(
                              label: "Full Address",
                              value: _data!["data"]["alamat"]?.toString(),
                              showCopy: true,
                            ),
                            _buildInfoItem(
                              label: "TPS",
                              value: _data!["data"]["tps"]?.toString(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildInfoCard(
                          title: "Additional Information",
                          icon: Icons.info,
                          color: warningOrange,
                          children: [
                            _buildInfoItem(
                              label: "Zodiac",
                              value: _data!["data"]["zodiak"]?.toString(),
                            ),
                            _buildInfoItem(
                              label: "Upcoming Birthday",
                              value: _data!["data"]["ultah_mendatang"]?.toString(),
                            ),
                            _buildInfoItem(
                              label: "Market Day",
                              value: _data!["data"]["pasaran"]?.toString(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String? value,
    bool showCopy = false,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDarker,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentPink.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: lightPink,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showCopy)
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: accentPink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.copy, color: accentPink, size: 18),
                onPressed: () => _copyToClipboard(value, label),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
                tooltip: 'Copy $label',
              ),
            ),
        ],
      ),
    );
  }
}