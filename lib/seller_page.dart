import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SellerPage extends StatefulWidget {
  final String keyToken;

  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> with TickerProviderStateMixin {
  final _newUser = TextEditingController();
  final _newPass = TextEditingController();
  final _days = TextEditingController();
  final _editUser = TextEditingController();
  final _editDays = TextEditingController();
  bool loading = false;
  bool isCreating = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _newUser.dispose();
    _newPass.dispose();
    _days.dispose();
    _editUser.dispose();
    _editDays.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final u = _newUser.text.trim(), p = _newPass.text.trim(), d = _days.text.trim();
    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _showNotification("Error", "Semua field wajib diisi", dangerRed);
      return;
    }

    setState(() {
      loading = true;
      isCreating = true;
    });

    final res = await http.get(Uri.parse(
        "http://152.53.249.119:2028/createAccount?key=${widget.keyToken}&newUser=$u&pass=$p&day=$d"));
    final data = jsonDecode(res.body);

    if (data['created'] == true) {
      _showNotification("Success", "Akun berhasil dibuat!", successGreen);
      _newUser.clear();
      _newPass.clear();
      _days.clear();
    } else {
      _showNotification("Error", data['message'] ?? 'Gagal membuat akun.', dangerRed);
    }

    setState(() {
      loading = false;
      isCreating = false;
    });
  }

  Future<void> _edit() async {
    final u = _editUser.text.trim(), d = _editDays.text.trim();
    if (u.isEmpty || d.isEmpty) {
      _showNotification("Error", "Username dan durasi wajib diisi", dangerRed);
      return;
    }

    setState(() {
      loading = true;
      isCreating = false;
    });

    final res = await http.get(Uri.parse(
        "http://152.53.249.119:2028/editUser?key=${widget.keyToken}&username=$u&addDays=$d"));
    final data = jsonDecode(res.body);

    if (data['edited'] == true) {
      _showNotification("Success", "Durasi berhasil diperbarui.", successGreen);
      _editUser.clear();
      _editDays.clear();
    } else {
      _showNotification("Error", data['message'] ?? 'Gagal mengubah durasi.', dangerRed);
    }

    setState(() {
      loading = false;
      isCreating = false;
    });
  }

  void _showNotification(String title, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDarker,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
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
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  color == successGreen ? Icons.check_circle :
                  color == dangerRed ? Icons.error : Icons.info,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildModernInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardDarker,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentPink.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: accentPink),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Widget> inputs,
    required VoidCallback onPressed,
    required String buttonText,
    Color buttonColor = const Color(0xFFF63B82),
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: buttonColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: buttonColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...inputs,
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [buttonColor, buttonColor.withOpacity(0.8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: loading && isCreating == (buttonText == "CREATE ACCOUNT")
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : loading && isCreating == (buttonText == "UPDATE DURATION")
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
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
                      const Text(
                        "Account Management",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Create new accounts or extend existing ones",
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

                _buildActionCard(
                  title: "Create New Account",
                  description: "Create a new user account with specified duration",
                  icon: Icons.person_add,
                  inputs: [
                    _buildModernInput(
                      label: "Username",
                      controller: _newUser,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildModernInput(
                      label: "Password",
                      controller: _newPass,
                      icon: Icons.lock,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    _buildModernInput(
                      label: "Duration (days)",
                      controller: _days,
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  onPressed: _create,
                  buttonText: "CREATE ACCOUNT",
                  buttonColor: accentPink,
                ),

                _buildActionCard(
                  title: "Extend Account Duration",
                  description: "Add more days to an existing user account",
                  icon: Icons.update,
                  inputs: [
                    _buildModernInput(
                      label: "Username",
                      controller: _editUser,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildModernInput(
                      label: "Additional Days",
                      controller: _editDays,
                      icon: Icons.add_circle,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  onPressed: _edit,
                  buttonText: "UPDATE DURATION",
                  buttonColor: successGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}