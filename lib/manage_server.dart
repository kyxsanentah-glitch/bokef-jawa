import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageServerPage extends StatefulWidget {
  final String keyToken;
  const ManageServerPage({super.key, required this.keyToken});

  @override
  State<ManageServerPage> createState() => _ManageServerPageState();
}

class _ManageServerPageState extends State<ManageServerPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> vpsList = [];
  bool isLoading = false;
  bool isAdding = false;

  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

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

    _fetchVpsList();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _hostController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _fetchVpsList() async {
    setState(() => isLoading = true);
    final uri = Uri.parse('http://152.53.249.119:2028/myServer?key=${widget.keyToken}');
    try {
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      setState(() {
        vpsList = List<Map<String, dynamic>>.from(data);
      });
    } catch (_) {
      _showNotification("Error", "Gagal mengambil data VPS.", dangerRed);
    }
    setState(() => isLoading = false);
  }

  Future<void> _addVps() async {
    final host = _hostController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    if (host.isEmpty || user.isEmpty || pass.isEmpty) {
      _showNotification("Error", "Isi semua field terlebih dahulu.", dangerRed);
      return;
    }

    setState(() => isAdding = true);
    Navigator.pop(context);

    final uri = Uri.parse('http://152.53.249.119:2028/addServer');
    try {
      final res = await http.post(uri, body: {
        'key': widget.keyToken,
        'host': host,
        'username': user,
        'password': pass,
      });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _hostController.clear();
        _userController.clear();
        _passController.clear();
        _showNotification("Success", "VPS berhasil ditambahkan.", successGreen);
        _fetchVpsList();
      } else {
        _showNotification("Error", data['error'] ?? 'Gagal menambah VPS', dangerRed);
      }
    } catch (_) {
      _showNotification("Error", "Gagal terhubung ke server.", dangerRed);
    }
    setState(() => isAdding = false);
  }

  Future<void> _deleteVps(String host) async {
    final confirmed = await _showConfirmationDialog(
      "Hapus VPS",
      "Apakah Anda yakin ingin menghapus VPS dengan host $host?",
    );

    if (!confirmed) return;

    final uri = Uri.parse('http://152.53.249.119:2028/delServer');
    try {
      final res = await http.post(uri, body: {
        'key': widget.keyToken,
        'host': host,
      });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _showNotification("Success", "VPS berhasil dihapus.", successGreen);
        _fetchVpsList();
      } else {
        _showNotification("Error", "Gagal menghapus VPS.", dangerRed);
      }
    } catch (_) {
      _showNotification("Error", "Gagal menghubungi server.", dangerRed);
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardDarker,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: dangerRed.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: dangerRed),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "BATAL",
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              foregroundColor: Colors.white,
            ),
            child: const Text("HAPUS"),
          ),
        ],
      ),
    );
    return result ?? false;
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

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: cardDarker,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentPink.withOpacity(0.3)),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentPink.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: accentPink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Tambah VPS Baru",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildModernInput("IP VPS", _hostController, Icons.dns),
              const SizedBox(height: 16),
              _buildModernInput("Username", _userController, Icons.person),
              const SizedBox(height: 16),
              _buildModernInput("Password", _passController, Icons.lock, obscureText: true),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "BATAL",
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addVps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("TAMBAH"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput(String label, TextEditingController controller, IconData icon, {bool obscureText = false}) {
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
            color: cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentPink.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
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

  Widget _buildVpsCard(Map<String, dynamic> vps, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentPink.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentPink.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.dns,
                    color: accentPink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "VPS Server",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        vps['host'],
                        style: TextStyle(
                          color: lightPink,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: successGreen.withOpacity(0.5)),
                  ),
                  child: Text(
                    "ACTIVE",
                    style: TextStyle(
                      color: successGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardDarker,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Username: ${vps['username']}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _deleteVps(vps['host']),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text("HAPUS"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dangerRed,
                    side: BorderSide(color: dangerRed.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                Icons.dns,
                color: accentPink,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Server Management",
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
          child: RefreshIndicator(
            color: accentPink,
            onRefresh: _fetchVpsList,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "My VPS Servers",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${vpsList.length} Servers",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Manage your virtual private servers",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

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
                      onPressed: _showAddDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "ADD NEW SERVER",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (isLoading)
                    Container(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: accentPink,
                        ),
                      ),
                    )
                  else if (vpsList.isEmpty)
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentPink.withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dns_outlined,
                            size: 64,
                            color: accentPink.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No VPS Servers",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Add your first VPS server to get started",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: List.generate(
                        vpsList.length,
                            (index) => _buildVpsCard(vpsList[index], index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}