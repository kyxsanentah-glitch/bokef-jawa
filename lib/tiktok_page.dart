import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TiktokDownloaderPage extends StatefulWidget {
  const TiktokDownloaderPage({super.key});

  @override
  State<TiktokDownloaderPage> createState() => _TiktokDownloaderPageState();
}

class _TiktokDownloaderPageState extends State<TiktokDownloaderPage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _videoData;
  String? _errorMessage;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  final Color primaryDark = Color(0xFF270A1A);
  final Color primaryPink = Color(0xFF8A1E5A);
  final Color accentPink = Color(0xFFF63B82);
  final Color lightPink = Color(0xFFFA60A5);
  final Color primaryWhite = Colors.white;
  final Color accentGrey = Colors.grey.shade400;
  final Color glassColor = Color(0x1FFFFFFF);

  @override
  void dispose() {
    _urlController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _downloadTiktok() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = "URL TikTok tidak boleh kosong.";
        _videoData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoData = null;
      _videoController?.dispose();
      _chewieController?.dispose();
    });

    final apiUrl = Uri.parse("https://api.siputzx.my.id/api/d/tiktok?url=$url");

    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          setState(() {
            _videoData = json['data'];
          });
          _initializeVideoPlayer();
        } else {
          setState(() {
            _errorMessage = "Gagal mengambil data TikTok.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal terhubung ke server.";
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

  void _initializeVideoPlayer() {
    if (_videoData?['urls'] != null && _videoData!['urls'].isNotEmpty) {
      final videoUrl = _videoData!['urls'][0];
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              autoPlay: true,
              looping: false,
              showControls: true,
              materialProgressColors: ChewieProgressColors(
                playedColor: accentPink,
                handleColor: lightPink,
                backgroundColor: accentGrey.withOpacity(0.3),
                bufferedColor: accentGrey.withOpacity(0.2),
              ),
            );
          });
        });
    }
  }

  Future<void> _shareVideo() async {
    if (_videoData?['urls'] == null || _videoData!['urls'].isEmpty) return;

    try {
      final videoUrl = _videoData!['urls'][0];
      final response = await http.get(Uri.parse(videoUrl));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tiktok_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles([XFile(file.path)],
        text: 'Video TikTok dari: ${_videoData!['metadata']?['creator'] ?? 'Unknown'}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e', style: TextStyle(color: primaryWhite)),
          backgroundColor: primaryPink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryDark,
              Color(0xFF37152C),
              Color(0xFF2A0F17),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: glassColor,
                    borderRadius: BorderRadius.circular(16),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, color: lightPink, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'TIKTOK DOWNLOADER',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          color: primaryWhite,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

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
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _urlController,
                        style: TextStyle(color: primaryWhite, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Masukkan URL TikTok',
                          labelStyle: TextStyle(color: lightPink),
                          hintText: 'Contoh: https://vt.tiktok.com/xxx/',
                          hintStyle: TextStyle(color: accentGrey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: lightPink, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          prefixIcon: Icon(Icons.link, color: lightPink),
                          suffixIcon: _isLoading
                              ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: lightPink,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [primaryPink, accentPink],
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
                          onPressed: _isLoading ? null : _downloadTiktok,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: primaryWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isLoading ? Icons.hourglass_top : Icons.download, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _isLoading ? 'PROSES...' : 'DOWNLOAD',
                                style: TextStyle(
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
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.redAccent, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                if (_videoData != null)
                  Expanded(
                    child: SingleChildScrollView(
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
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryPink, accentPink],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentPink.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.videocam, color: primaryWhite, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    "VIDEO PREVIEW",
                                    style: TextStyle(
                                      color: primaryWhite,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (_chewieController != null)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: _videoController!.value.aspectRatio,
                                    child: Chewie(controller: _chewieController!),
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(color: lightPink),
                                      SizedBox(height: 16),
                                      Text(
                                        'Loading video...',
                                        style: TextStyle(
                                          color: lightPink,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            if (_videoData?['metadata'] != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _videoData!['metadata']['title'] ?? 'No Title',
                                      style: TextStyle(
                                        color: primaryWhite,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.person, color: lightPink, size: 16),
                                        SizedBox(width: 8),
                                        Text(
                                          'Creator: ${_videoData!['metadata']['creator'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            color: accentGrey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
                                    color: lightPink.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _shareVideo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: primaryWhite,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.share, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'SHARE VIDEO',
                                      style: TextStyle(
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
                    ),
                  ),

                if (_videoData == null && !_isLoading && _errorMessage == null)
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(30),
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
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_library,
                              size: 80,
                              color: lightPink.withOpacity(0.7),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'TikTok Downloader',
                              style: TextStyle(
                                color: primaryWhite,
                                fontSize: 18,
                                fontFamily: 'Orbitron',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Masukkan URL TikTok untuk mendownload video',
                                style: TextStyle(
                                  color: accentGrey,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}