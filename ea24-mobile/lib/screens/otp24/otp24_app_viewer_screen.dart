import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'otp24_service.dart';

/// OTP24 App Viewer — fetches nodes/cookies and opens in WebView or browser
class OTP24AppViewerScreen extends StatefulWidget {
  final int appId;
  final String appName;
  final String appIconUrl;
  final String fallbackUrl;

  const OTP24AppViewerScreen({
    super.key,
    required this.appId,
    required this.appName,
    required this.appIconUrl,
    required this.fallbackUrl,
  });

  @override
  State<OTP24AppViewerScreen> createState() => _OTP24AppViewerScreenState();
}

class _OTP24AppViewerScreenState extends State<OTP24AppViewerScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String _status = 'กำลังค้นหาเซิร์ฟเวอร์...';
  String? _error;
  Map<String, dynamic>? _selectedNode;
  Map<String, dynamic>? _cookieData;

  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _autoFetch();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _autoFetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _status = 'กำลังค้นหาเซิร์ฟเวอร์...';
    });

    try {
      // 1. Fetch nodes
      final nodesResult = await OTP24Service.fetchNodes(widget.appId);
      List<Map<String, dynamic>> nodes = [];

      if (nodesResult is List) {
        nodes = List<Map<String, dynamic>>.from(
          nodesResult.where((e) => e is Map).map((e) => Map<String, dynamic>.from(e)),
        );
      } else if (nodesResult is Map && nodesResult['status'] == 'error') {
        throw Exception(nodesResult['message']?.toString() ?? 'ดึงเซิร์ฟเวอร์ไม่ได้');
      }

      // Filter to working/accessible nodes
      final okNodes = nodes.where((n) =>
        (n['is_working'] == true || n['is_working'] == 1) &&
        (n['can_access'] == true || n['can_access'] == 1)
      ).toList();

      if (okNodes.isEmpty) throw Exception('ไม่พบเซิร์ฟเวอร์ที่ใช้งานได้');

      setState(() {
        _selectedNode = okNodes.first;
        _status = 'กำลังดึง Cookie...';
      });

      // 2. Fetch cookie from first working node
      final nodeId = (okNodes.first['id'] as num?)?.toInt() ?? 0;
      final cookieResult = await OTP24Service.fetchCookie(nodeId);

      if (cookieResult is Map<String, dynamic>) {
        if (cookieResult['status'] == 'error') {
          throw Exception(cookieResult['message']?.toString() ?? 'ดึง Cookie ไม่สำเร็จ');
        }
        setState(() {
          _cookieData = cookieResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openInBrowser() async {
    final url = _cookieData?['target_url']?.toString() ?? widget.fallbackUrl;
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1422),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
        ),
        title: Row(
          children: [
            if (widget.appIconUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.appIconUrl,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _autoFetch,
              icon: const Icon(Icons.refresh, color: Colors.white54),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _error != null
              ? _buildErrorView()
              : _buildSuccessView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spinning logo
          AnimatedBuilder(
            animation: _spinController,
            builder: (_, child) => Transform.rotate(
              angle: _spinController.value * 6.28,
              child: child,
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: widget.appIconUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: widget.appIconUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.apps, size: 36, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.apps, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            widget.appName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _status,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF5722)),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final targetUrl = _cookieData?['target_url']?.toString() ?? widget.fallbackUrl;
    final cookies = _cookieData?['cookies'] as List?;
    final cookieCount = cookies?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Success header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.15),
                  const Color(0xFF0A0E1A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.appIconUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.appIconUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF1A1F2E),
                            child: const Icon(Icons.apps, size: 36, color: Colors.white),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF1A1F2E),
                          child: const Icon(Icons.apps, size: 36, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 16),
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
                const SizedBox(height: 8),
                Text(
                  '${widget.appName} พร้อมแล้ว!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ดึง Cookie สำเร็จ $cookieCount cookies',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info cards
          _infoCard('🌐 Target URL', targetUrl, Icons.link),
          const SizedBox(height: 10),
          _infoCard('🍪 Cookies', '$cookieCount cookies loaded', Icons.cookie),
          const SizedBox(height: 10),
          if (_selectedNode != null)
            _infoCard(
              '🖥️ Server',
              _selectedNode!['name']?.toString() ?? 'Node ${_selectedNode!['id']}',
              Icons.dns,
            ),
          const SizedBox(height: 30),

          // Open button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser, size: 22),
              label: Text(
                'เปิด ${widget.appName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Force refresh button
          TextButton.icon(
            onPressed: () async {
              setState(() {
                _isLoading = true;
                _status = 'Force refreshing...';
              });
              final nodeId = (_selectedNode?['id'] as num?)?.toInt() ?? 0;
              final result = await OTP24Service.fetchCookie(nodeId, force: true);
              if (result is Map<String, dynamic> && result['status'] != 'error') {
                setState(() {
                  _cookieData = result;
                  _isLoading = false;
                });
              } else {
                setState(() {
                  _isLoading = false;
                  _error = result?['message']?.toString() ?? 'Force refresh failed';
                });
              }
            },
            icon: Icon(Icons.refresh, size: 18, color: Colors.white.withOpacity(0.4)),
            label: Text(
              'Force Refresh Cookie',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
            ),
            const SizedBox(height: 20),
            Text(
              'เปิด ${widget.appName} ไม่สำเร็จ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _autoFetch,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
