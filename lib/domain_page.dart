import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class DomainOsintPage extends StatefulWidget {
  const DomainOsintPage({super.key});

  @override
  State<DomainOsintPage> createState() => _DomainOsintPageState();
}

class _DomainOsintPageState extends State<DomainOsintPage> {
  final TextEditingController _domainController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _dnsData;
  List<dynamic>? _subdomainsData;
  String? _errorMessage;

  Future<void> _checkDomain() async {
    final domain = _domainController.text.trim();
    if (domain.isEmpty) {
      setState(() {
        _errorMessage = "Domain tidak boleh kosong.";
        _dnsData = null;
        _subdomainsData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _dnsData = null;
      _subdomainsData = null;
    });

    try {
      final dnsResult = await _fetchDnsInfo(domain);
      final subdoResult = await _fetchSubdomains(domain);

      if (dnsResult != null && subdoResult != null) {
        setState(() {
          _dnsData = dnsResult;
          _subdomainsData = subdoResult;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data domain.";
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

  Future<Map<String, dynamic>?> _fetchDnsInfo(String domain) async {
    final url = Uri.parse("https://api.siputzx.my.id/api/tools/dns?domain=$domain");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['status'] == true ? json['data'] : null;
    }
    return null;
  }

  Future<List<dynamic>?> _fetchSubdomains(String domain) async {
    final url = Uri.parse("https://api.siputzx.my.id/api/tools/subdomains?domain=$domain");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['status'] == true ? json['data'] : null;
    }
    return null;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label disalin ke clipboard'),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.black, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
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

  Widget _buildInfoRow({
    required String label,
    required String? value,
    bool showCopyButton = false,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
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
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showCopyButton)
            IconButton(
              icon: Icon(Icons.copy, color: Colors.grey[700], size: 20),
              onPressed: () => _copyToClipboard(value, label),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40),
              tooltip: 'Salin $label',
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDnsRecords() {
    if (_dnsData == null || _dnsData!['records'] == null) return [];

    final records = _dnsData!['records'] as Map<String, dynamic>;
    final widgets = <Widget>[];

    if (records['ns']?['response']?['answer'] != null) {
      final nsRecords = records['ns']!['response']!['answer'] as List;
      if (nsRecords.isNotEmpty) {
        widgets.addAll([
          const Text(
            'Name Servers',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...nsRecords.map((record) => _buildInfoRow(
            label: 'NS Record',
            value: record['record']?['target']?.toString(),
            showCopyButton: true,
          )),
          const SizedBox(height: 16),
        ]);
      }
    }

    if (records['soa']?['response']?['answer'] != null) {
      final soaRecords = records['soa']!['response']!['answer'] as List;
      if (soaRecords.isNotEmpty) {
        final soa = soaRecords.first['record'];
        widgets.addAll([
          const Text(
            'SOA Record',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            label: 'Primary NS',
            value: soa?['host']?.toString(),
            showCopyButton: true,
          ),
          _buildInfoRow(
            label: 'Admin Email',
            value: soa?['admin']?.toString(),
            showCopyButton: true,
          ),
          _buildInfoRow(
            label: 'Serial',
            value: soa?['serial']?.toString(),
          ),
          _buildInfoRow(
            label: 'Refresh',
            value: soa?['refresh']?.toString(),
          ),
          _buildInfoRow(
            label: 'Retry',
            value: soa?['retry']?.toString(),
          ),
          _buildInfoRow(
            label: 'Expire',
            value: soa?['expire']?.toString(),
          ),
          _buildInfoRow(
            label: 'Minimum TTL',
            value: soa?['minimum']?.toString(),
          ),
          const SizedBox(height: 16),
        ]);
      }
    }

    if (records['a']?['response']?['answer'] != null) {
      final aRecords = records['a']!['response']!['answer'] as List;
      if (aRecords.isNotEmpty) {
        widgets.addAll([
          const Text(
            'A Records',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...aRecords.map((record) => _buildInfoRow(
            label: 'A Record',
            value: record['record']?['data']?.toString(),
            showCopyButton: true,
          )),
        ]);
      }
    }

    return widgets;
  }

  List<Widget> _buildSubdomainsList() {
    if (_subdomainsData == null) return [];

    final cleanSubdomains = _subdomainsData!
        .map((item) => item.toString().split('\n').last.trim())
        .where((subdomain) => subdomain.isNotEmpty && !subdomain.startsWith('*'))
        .toSet()
        .toList()
      ..sort();

    return [
      Text(
        'Ditemukan ${cleanSubdomains.length} subdomain',
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 12),
      ...cleanSubdomains.map((subdomain) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Row(
          children: [
            Icon(Icons.link, color: Colors.grey[700], size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subdomain,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy, color: Colors.grey[700], size: 18),
              onPressed: () => _copyToClipboard(subdomain, 'Subdomain'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36),
              tooltip: 'Salin subdomain',
            ),
          ],
        ),
      )).toList(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'DOMAIN OSINT',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.pink,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _domainController,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Masukkan Domain',
                        labelStyle: const TextStyle(color: Colors.black87),
                        hintText: 'Contoh: nullxteam.fun',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.pink, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        suffixIcon: _isLoading
                            ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.pink,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                            : null,
                      ),
                      onSubmitted: (_) => _checkDomain(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkDomain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isLoading ? Icons.hourglass_top : Icons.search, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _isLoading ? 'MEMPROSES...' : 'CEK DOMAIN',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              if (_dnsData != null || _subdomainsData != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_dnsData != null)
                          _buildCategoryCard(
                            title: "INFORMASI DOMAIN",
                            icon: Icons.domain,
                            children: [
                              _buildInfoRow(
                                label: "Domain",
                                value: _dnsData!['unicodeDomain']?.toString(),
                                showCopyButton: true,
                              ),
                              _buildInfoRow(
                                label: "Punycode",
                                value: _dnsData!['punycodeDomain']?.toString(),
                                showCopyButton: true,
                              ),
                              ..._buildDnsRecords(),
                            ],
                          ),

                        const SizedBox(height: 16),

                        if (_subdomainsData != null)
                          _buildCategoryCard(
                            title: "SUBDOMAINS",
                            icon: Icons.list,
                            children: _buildSubdomainsList(),
                          ),

                        const SizedBox(height: 16),

                        if (_dnsData != null && _dnsData!['records'] != null)
                          _buildCategoryCard(
                            title: "INFORMASI SERVER",
                            icon: Icons.dns,
                            children: [
                              if (_dnsData!['records']['a']?['query']?['server'] != null)
                                _buildInfoRow(
                                  label: "DNS Server",
                                  value: _dnsData!['records']['a']!['query']!['server']!['ip']?.toString(),
                                  showCopyButton: true,
                                ),
                              if (_dnsData!['records']['a']?['query']?['server']?['location'] != null)
                                _buildInfoRow(
                                  label: "Lokasi Server",
                                  value: "Lat: ${_dnsData!['records']['a']!['query']!['server']!['location']!['lat']}, Lon: ${_dnsData!['records']['a']!['query']!['server']!['location']!['lon']}",
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}