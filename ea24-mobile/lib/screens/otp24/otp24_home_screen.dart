import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp24_service.dart';
import 'otp24_app_viewer_screen.dart';
import 'otp24_settings_screen.dart';

/// OTP24 Home Screen — Elite Quiz-inspired clean design
class OTP24HomeScreen extends StatefulWidget {
  const OTP24HomeScreen({super.key});

  @override
  State<OTP24HomeScreen> createState() => _OTP24HomeScreenState();
}

class _OTP24HomeScreenState extends State<OTP24HomeScreen> {
  // State
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _apps = [];
  String? _plan;
  int _usedToday = 0;
  int _dailyLimit = 5;
  String? _updatedAt;
  String? _deviceId;
  bool _deviceSynced = false;
  List<int> _cachedAppIds = [];

  // Colors (Elite Quiz style)
  static const _primaryColor = Color(0xFFEF5388);
  static const _textColor = Color(0xFF45536D);
  static const _bgColor = Color(0xFFF3F7FA);
  static const _cardColor = Colors.white;
  static const _successColor = Color(0xFF5DB760);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _deviceId = await OTP24Service.getDeviceId();
    if (mounted) setState(() {});
    await _syncDevice();
    await _fetchAll();
  }

  Future<void> _syncDevice() async {
    final result = await OTP24Service.syncDeviceId();
    if (mounted) {
      setState(() {
        _deviceSynced = result['status'] == 'success';
      });
    }
  }

  Future<void> _fetchAll() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        OTP24Service.fetchApps(),
        OTP24Service.fetchAccountInfo(),
        OTP24Service.fetchCachedAppIds(),
      ]);

      final appsData = results[0] as Map<String, dynamic>;
      final cached = results[2] as List<int>;

      if (mounted) {
        setState(() {
          _cachedAppIds = cached;

          if (appsData['status'] == 'error') {
            _error = appsData['message']?.toString();
          } else if (appsData.containsKey('apps') && appsData['apps'] is List) {
            _plan = appsData['plan']?.toString() ?? 'free';
            _usedToday = (appsData['used_today'] as num?)?.toInt() ?? 0;
            _dailyLimit = (appsData['daily_limit'] as num?)?.toInt() ?? 5;
            _updatedAt = appsData['updated_at']?.toString();

            _apps = List<Map<String, dynamic>>.from(
              (appsData['apps'] as List)
                  .where((e) => e is Map)
                  .map((e) => Map<String, dynamic>.from(e)),
            );
            _apps.sort((a, b) =>
                (a['sort_order'] ?? 99).compareTo(b['sort_order'] ?? 99));
          } else {
            _error = 'Server connected but no apps data yet';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  String _fmtDate(String? d) {
    if (d == null) return '-';
    try {
      final diff = DateTime.now().difference(DateTime.parse(d));
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return d;
    }
  }

  Map<String, List<Map<String, dynamic>>> _grouped() {
    final m = <String, List<Map<String, dynamic>>>{};
    for (final a in _apps) {
      m.putIfAbsent(a['category']?.toString() ?? 'Other', () => []).add(a);
    }
    return m;
  }

  double get _hzMargin => MediaQuery.of(context).size.width * 0.05;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAll,
          color: _primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildStatusCard()),
              SliverToBoxAdapter(child: _buildDevicePanel()),
              if (_isLoading && _apps.isEmpty)
                const SliverFillRemaining(child: _LoadingView())
              else if (_error != null && _apps.isEmpty)
                SliverFillRemaining(child: _buildErrorView())
              else ...[
                ..._grouped().entries.map((entry) => SliverToBoxAdapter(
                      child: _buildCategorySection(entry.key, entry.value),
                    )),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(_hzMargin, 16, _hzMargin, 0),
      child: Row(
        children: [
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.local_fire_department,
                  color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OTP24HR HUB',
                  style: GoogleFonts.nunito(
                    color: _textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Secure System',
                  style: GoogleFonts.nunito(
                    color: _textColor.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // Settings
          _buildIconButton(
            icon: Icons.settings_outlined,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OTP24SettingsScreen()),
              );
              if (result == true) _fetchAll();
            },
          ),
          const SizedBox(width: 8),
          // Refresh
          _buildIconButton(
            icon: _isLoading ? null : Icons.refresh,
            onTap: _isLoading ? null : _fetchAll,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryColor,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({IconData? icon, VoidCallback? onTap, Widget? child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
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
        child: Center(
          child: child ?? Icon(icon, color: _textColor.withOpacity(0.6), size: 20),
        ),
      ),
    );
  }

  // ── Status Card ────────────────────────────────────
  Widget _buildStatusCard() {
    final isOnline = _apps.isNotEmpty && _error == null;
    return Container(
      margin: EdgeInsets.fromLTRB(_hzMargin, 20, _hzMargin, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? _primaryColor : Colors.red).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isOnline ? _successColor : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: isOnline ? _successColor : Colors.red,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'OTP24 Online' : 'Connection Error',
                      style: GoogleFonts.nunito(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOnline
                          ? '${_plan?.toUpperCase()} | ${_apps.length} apps | ${_fmtDate(_updatedAt)}'
                          : _error ?? '',
                      style: GoogleFonts.nunito(
                        color: _textColor.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isOnline) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _dailyLimit > 0 ? _usedToday / _dailyLimit : 0,
                backgroundColor: _primaryColor.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(
                  _usedToday >= _dailyLimit ? Colors.red : _primaryColor,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Used: $_usedToday / $_dailyLimit today',
              style: GoogleFonts.nunito(
                color: _textColor.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Device Panel ───────────────────────────────────
  Widget _buildDevicePanel() {
    return Container(
      margin: EdgeInsets.fromLTRB(_hzMargin, 12, _hzMargin, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
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
              color: (_deviceSynced ? _successColor : _primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _deviceSynced ? Icons.verified_outlined : Icons.fingerprint,
              color: _deviceSynced ? _successColor : _primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _deviceSynced ? 'Device Synced' : 'Device ID',
                  style: GoogleFonts.nunito(
                    color: _textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _deviceId != null
                      ? '${_deviceId!.substring(0, _deviceId!.length.clamp(0, 12))}...'
                      : 'Generating...',
                  style: const TextStyle(
                    color: Color(0x6645536D),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (!_deviceSynced)
            TextButton(
              onPressed: _syncDevice,
              style: TextButton.styleFrom(
                backgroundColor: _primaryColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
              child: Text('SYNC',
                  style: GoogleFonts.nunito(
                      color: _primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('LOCKED',
                  style: GoogleFonts.nunito(
                      color: _successColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }

  // ── Category Section ───────────────────────────────
  Widget _buildCategorySection(
      String category, List<Map<String, dynamic>> apps) {
    final displayNames = {
      'streaming': 'Streaming',
      'social': 'Social',
      'music': 'Music',
      'tools': 'Tools',
      'education': 'Education',
      'design': 'Design',
      'ai': 'AI',
      'vpn': 'VPN',
    };

    final categoryIcons = {
      'streaming': Icons.play_circle_outline,
      'social': Icons.people_outline,
      'music': Icons.music_note_outlined,
      'tools': Icons.build_outlined,
      'education': Icons.school_outlined,
      'design': Icons.palette_outlined,
      'ai': Icons.auto_awesome_outlined,
      'vpn': Icons.lock_outline,
    };

    final displayName = displayNames[category.toLowerCase()] ?? category;
    final icon = categoryIcons[category.toLowerCase()] ?? Icons.apps;

    return Padding(
      padding: EdgeInsets.fromLTRB(_hzMargin, 24, _hzMargin, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Row(
            children: [
              Icon(icon, color: _primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                displayName,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${apps.length}',
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: _primaryColor,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // App Grid — 2 columns like ui2
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: apps.length,
            itemBuilder: (ctx, i) => _buildAppTile(apps[i]),
          ),
        ],
      ),
    );
  }

  // ── App Tile ───────────────────────────────────────
  Widget _buildAppTile(Map<String, dynamic> app) {
    final locked = app['is_locked'] == true;
    final name = app['name']?.toString() ?? 'App';
    final icon = app['icon_url']?.toString() ?? '';
    final appId = (app['id'] as num?)?.toInt() ?? 0;
    final hasCachedCookie = _cachedAppIds.contains(appId);

    return GestureDetector(
      onTap: () {
        if (locked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(app['requirement'] ?? 'Premium only'),
              backgroundColor: Colors.orange[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTP24AppViewerScreen(
                appId: appId,
                appName: name,
                appIconUrl: icon,
                fallbackUrl: app['target_url']?.toString() ?? '',
              ),
            ),
          ).then((_) => _fetchAll());
        }
      },
      child: Opacity(
        opacity: locked ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(14),
            border: hasCachedCookie
                ? Border.all(color: _successColor.withOpacity(0.3))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // App icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: icon.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: icon,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                            Icons.apps, size: 22, color: _textColor.withOpacity(0.3)),
                      )
                    : Icon(Icons.apps, size: 22, color: _textColor.withOpacity(0.3)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasCachedCookie)
                      Text(
                        'Cached',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: _successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (locked)
                Icon(Icons.lock_outline, size: 16, color: Colors.orange[400]),
              if (hasCachedCookie && !locked)
                Icon(Icons.check_circle, size: 16, color: _successColor),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error View ─────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 64, color: _textColor.withOpacity(0.15)),
            const SizedBox(height: 20),
            Text(
              'Connection Error',
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
              onPressed: _fetchAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
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

// ── Loading Animation ────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEF5388),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF5388).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.local_fire_department,
                  color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading...',
            style: GoogleFonts.nunito(
              color: const Color(0xFFEF5388),
              fontSize: 14,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              backgroundColor: const Color(0xFFEF5388).withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFEF5388)),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
