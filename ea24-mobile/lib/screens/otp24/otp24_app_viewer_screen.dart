import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'otp24_service.dart';

/// OTP24 App Viewer — Elite Quiz-inspired clean design
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
  String _status = 'Finding servers...';
  String? _error;
  Map<String, dynamic>? _selectedNode;
  Map<String, dynamic>? _cookieData;
  bool _usedCached = false;

  late AnimationController _pulseController;

  static const _primaryColor = Color(0xFFEF5388);
  static const _textColor = Color(0xFF45536D);
  static const _bgColor = Color(0xFFF3F7FA);
  static const _cardColor = Colors.white;
  static const _successColor = Color(0xFF5DB760);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _autoFetch();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _autoFetch({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _status = 'Finding servers...';
    });

    try {
      // ── Step 1: Fetch nodes (always needed to find node_id, server caches this)
      final nodesResult = await OTP24Service.fetchNodes(widget.appId);
      List<Map<String, dynamic>> nodes = [];

      if (nodesResult is List) {
        nodes = List<Map<String, dynamic>>.from(
          nodesResult.where((e) => e is Map).map((e) => Map<String, dynamic>.from(e)),
        );
      } else if (nodesResult is Map && nodesResult['status'] == 'error') {
        throw Exception(nodesResult['message']?.toString() ?? 'Failed to fetch servers');
      }

      final okNodes = nodes.where((n) =>
        (n['is_working'] == true || n['is_working'] == 1) &&
        (n['can_access'] == true || n['can_access'] == 1)
      ).toList();

      if (okNodes.isEmpty) throw Exception('No available servers found');

      final nodeId = (okNodes.first['id'] as num?)?.toInt() ?? 0;
      setState(() {
        _selectedNode = okNodes.first;
        _status = forceRefresh ? 'Fetching fresh cookie (1 quota)...' : 'Fetching cookie...';
      });

      // ── Step 2: Fetch cookie directly from otp24hr
      final cookieResult = await OTP24Service.fetchCookie(nodeId, force: forceRefresh, appId: widget.appId);

      if (cookieResult is Map<String, dynamic>) {
        if (cookieResult['status'] == 'error') {
          throw Exception(cookieResult['message']?.toString() ?? 'Failed to fetch cookie');
        }
        setState(() {
          _cookieData = cookieResult;
          _isLoading = false;
          _usedCached = !forceRefresh;
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
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildBackButton(),
        title: Row(
          children: [
            if (widget.appIconUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: widget.appIconUrl,
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.appName,
                style: GoogleFonts.nunito(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _autoFetch(forceRefresh: true),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.refresh, size: 18,
                      color: _textColor.withOpacity(0.5)),
                ),
              ),
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

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: _textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) => Transform.scale(
              scale: 0.9 + (_pulseController.value * 0.15),
              child: Opacity(
                opacity: 0.6 + (_pulseController.value * 0.4),
                child: child,
              ),
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.appIconUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.appIconUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: _primaryColor,
                        child: const Icon(Icons.apps, size: 36,
                            color: Colors.white),
                      ),
                    )
                  : Container(
                      color: _primaryColor,
                      child: const Icon(Icons.apps, size: 36,
                          color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            widget.appName,
            style: GoogleFonts.nunito(
              color: _textColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _status,
            style: GoogleFonts.nunito(
              color: _textColor.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: _primaryColor.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(_primaryColor),
                minHeight: 4,
              ),
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
          // Success Card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _successColor.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.15),
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
                            color: _bgColor,
                            child: Icon(Icons.apps, size: 36,
                                color: _textColor.withOpacity(0.3)),
                          ),
                        )
                      : Container(
                          color: _bgColor,
                          child: Icon(Icons.apps, size: 36,
                              color: _textColor.withOpacity(0.3)),
                        ),
                ),
                const SizedBox(height: 16),
                Icon(Icons.check_circle, color: _successColor, size: 32),
                const SizedBox(height: 8),
                Text(
                  '${widget.appName} Ready!',
                  style: GoogleFonts.nunito(
                    color: _textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cookieCount cookies loaded',
                  style: GoogleFonts.nunito(
                    color: _textColor.withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _usedCached ? _successColor.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _usedCached ? '✓ From Cache (no quota used)' : '⚡ Fresh fetch (1 quota used)',
                    style: GoogleFonts.nunito(
                      color: _usedCached ? _successColor : Colors.orange[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Info Cards
          _infoCard('Target URL', targetUrl, Icons.language_outlined),
          const SizedBox(height: 10),
          _infoCard('Cookies', '$cookieCount loaded', Icons.cookie_outlined),
          if (_selectedNode != null) ...[
            const SizedBox(height: 10),
            _infoCard(
              'Server',
              _selectedNode!['name']?.toString() ?? 'Node ${_selectedNode!['id']}',
              Icons.dns_outlined,
            ),
          ],
          const SizedBox(height: 28),

          // Open Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser, size: 22),
              label: Text(
                'Open ${widget.appName}',
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Force Refresh
          TextButton.icon(
            onPressed: () async {
              setState(() {
                _isLoading = true;
                _status = 'Force refreshing...';
              });
              final nodeId = (_selectedNode?['id'] as num?)?.toInt() ?? 0;
              final result = await OTP24Service.fetchCookie(nodeId, force: true);
              if (result is Map<String, dynamic> && result['status'] != 'error') {
                setState(() { _cookieData = result; _isLoading = false; });
              } else {
                setState(() {
                  _isLoading = false;
                  _error = result?['message']?.toString() ?? 'Force refresh failed';
                });
              }
            },
            icon: Icon(Icons.refresh, size: 16,
                color: _textColor.withOpacity(0.3)),
            label: Text(
              'Force Refresh Cookie',
              style: GoogleFonts.nunito(
                color: _textColor.withOpacity(0.3),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: _textColor.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    color: _textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
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
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(Icons.error_outline, size: 40, color: Colors.red[400]),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to open ${widget.appName}',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: _textColor.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _autoFetch,
              icon: const Icon(Icons.refresh),
              label: Text('Try Again', style: GoogleFonts.nunito()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
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
