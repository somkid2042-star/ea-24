import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'otp24_service.dart';
import 'otp24_app_viewer_screen.dart';
import 'otp24_settings_screen.dart';

/// OTP24 Home Screen — main dashboard mirroring the browser extension
class OTP24HomeScreen extends StatefulWidget {
  const OTP24HomeScreen({super.key});

  @override
  State<OTP24HomeScreen> createState() => _OTP24HomeScreenState();
}

class _OTP24HomeScreenState extends State<OTP24HomeScreen>
    with TickerProviderStateMixin {
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

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      // Fetch in parallel
      final results = await Future.wait([
        OTP24Service.fetchApps(),
        OTP24Service.fetchAccountInfo(),
        OTP24Service.fetchCachedAppIds(),
      ]);

      final appsData = results[0] as Map<String, dynamic>;
      // accountInfo available in results[1] if needed later
      final cached = results[2] as List<int>;

      if (mounted) {
        setState(() {
          _cachedAppIds = cached;

          if (appsData['status'] == 'error') {
            _error = appsData['message']?.toString();
          } else if (appsData.containsKey('apps') && appsData['apps'] is List) {
            // Valid response with apps
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
            // Server connected but no apps data (stale cache)
            _error = 'Server เชื่อมต่อได้ แต่ยังไม่มีข้อมูล apps\nกรุณา sync ผ่าน Extension หรือกด Force Refresh';
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
      if (diff.inMinutes < 1) return 'เมื่อกี้';
      if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
      if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
      return '${diff.inDays} วันที่แล้ว';
    } catch (_) {
      return d;
    }
  }

  Map<String, List<Map<String, dynamic>>> _grouped() {
    final m = <String, List<Map<String, dynamic>>>{};
    for (final a in _apps) {
      m.putIfAbsent(a['category']?.toString() ?? 'อื่นๆ', () => []).add(a);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAll,
          color: const Color(0xFFFF5722),
          backgroundColor: const Color(0xFF1A1F2E),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(child: _buildHeader()),
              // ── Device Panel ──
              SliverToBoxAdapter(child: _buildDevicePanel()),
              // ── Account Status Card ──
              SliverToBoxAdapter(child: _buildStatusCard()),
              // ── Body ──
              if (_isLoading && _apps.isEmpty)
                const SliverFillRemaining(child: _LoadingView())
              else if (_error != null && _apps.isEmpty)
                SliverFillRemaining(child: _buildErrorView())
              else ...[
                // App Categories
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Logo
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.local_fire_department,
                    color: Colors.white, size: 26),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OTP24HR HUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'SECURE SYSTEM',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          // Settings
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OTP24SettingsScreen()),
              );
              if (result == true) {
                _fetchAll();
              }
            },
            icon: const Icon(Icons.settings, color: Colors.white54),
          ),
          // Refresh
          IconButton(
            onPressed: _isLoading ? null : _fetchAll,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF5722),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  // ── Device Panel ───────────────────────────────────
  Widget _buildDevicePanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _deviceSynced
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : const Color(0xFFFF5722).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_deviceSynced ? const Color(0xFF4CAF50) : const Color(0xFFFF5722))
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _deviceSynced ? Icons.verified : Icons.fingerprint,
              color: _deviceSynced ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _deviceSynced ? 'Device Synced' : 'Device ID',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _deviceId != null
                      ? '${_deviceId!.substring(0, _deviceId!.length.clamp(0, 12))}...'
                      : 'Generating...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
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
                backgroundColor: const Color(0xFFFF5722).withOpacity(0.15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('SYNC',
                  style: TextStyle(
                      color: Color(0xFFFF5722),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('✓ LOCKED',
                  style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  // ── Status Card ────────────────────────────────────
  Widget _buildStatusCard() {
    final isOnline = _apps.isNotEmpty && _error == null;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [const Color(0xFF1A2332), const Color(0xFF0D1B2A)]
              : [const Color(0xFF2A1A1A), const Color(0xFF1A0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF00BCD4).withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? const Color(0xFF00BCD4) : Colors.red)
                .withOpacity(0.08),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isOnline ? const Color(0xFF00BCD4) : Colors.red)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline ? const Color(0xFF00BCD4) : Colors.red,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'OTP24 พร้อมใช้งาน' : 'ไม่สามารถเชื่อมต่อได้',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isOnline
                          ? '${_plan?.toUpperCase()} • ${_apps.length} แอพ • ${_fmtDate(_updatedAt)}'
                          : _error ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isOnline) ...[
            const SizedBox(height: 14),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _dailyLimit > 0 ? _usedToday / _dailyLimit : 0,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(
                  _usedToday >= _dailyLimit
                      ? Colors.red
                      : const Color(0xFF00BCD4),
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ใช้ไป: $_usedToday / $_dailyLimit ครั้ง',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Category Section ───────────────────────────────
  Widget _buildCategorySection(
      String category, List<Map<String, dynamic>> apps) {
    final displayNames = {
      'streaming': '🎬 สตรีมมิ่ง',
      'social': '👥 โซเชียล',
      'music': '🎵 เพลง',
      'tools': '🛠 เครื่องมือ',
      'education': '📚 การศึกษา',
      'design': '🎨 ดีไซน์',
      'ai': '🤖 AI',
      'vpn': '🔒 VPN',
    };
    final categoryColors = {
      'streaming': Colors.red,
      'social': Colors.blue,
      'music': Colors.green,
      'tools': Colors.orange,
      'education': Colors.purple,
      'design': Colors.pink,
      'ai': Colors.teal,
      'vpn': Colors.indigo,
    };

    final displayName =
        displayNames[category.toLowerCase()] ?? '📦 $category';
    final color = categoryColors[category.toLowerCase()] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${apps.length}',
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // App Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.75,
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
              content: Text('🔒 ${app['requirement'] ?? "Premium only"}'),
              backgroundColor: Colors.orange[800],
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
        opacity: locked ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasCachedCookie
                          ? const Color(0xFF4CAF50).withOpacity(0.4)
                          : Colors.white.withOpacity(0.06),
                    ),
                    boxShadow: [
                      if (hasCachedCookie)
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: icon.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: icon,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.apps,
                              size: 28,
                              color: Colors.grey),
                        )
                      : const Icon(Icons.apps,
                          size: 28, color: Colors.grey),
                ),
                if (locked)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.lock,
                          size: 8, color: Colors.white),
                    ),
                  ),
                if (hasCachedCookie)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF4CAF50).withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check,
                          size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
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
            Icon(Icons.cloud_off,
                size: 64, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 20),
            const Text(
              'ไม่สามารถเชื่อมต่อ OTP24 ได้',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
              onPressed: _fetchAll,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
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
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(Icons.local_fire_department,
                  color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'SECURE INITIALIZING...',
            style: TextStyle(
              color: Color(0xFFFF5722),
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF5722)),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}
