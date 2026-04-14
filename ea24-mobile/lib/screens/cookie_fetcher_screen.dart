import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import '../notifier/trading_provider.dart';
import '../utils/app_style.dart';
import '../utils/color_utils.dart';

class CookieFetcherScreen extends StatefulWidget {
  const CookieFetcherScreen({super.key});

  @override
  State<CookieFetcherScreen> createState() => _CookieFetcherScreenState();
}

class _CookieFetcherScreenState extends State<CookieFetcherScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _apps = [];
  String? _plan;
  String? _updatedAt;
  int _usedToday = 0;
  int _dailyLimit = 5;
  bool _isAppLoading = false;
  String? _loadingAppName;

  @override
  void initState() {
    super.initState();
    _fetchApps();
  }

  Future<void> _fetchApps() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final provider = Provider.of<TradingProvider>(context, listen: false);
      final json = jsonDecode(await provider.fetchOtp24Cookies());
      if (json is Map<String, dynamic>) {
        setState(() {
          _updatedAt = json['updated_at']?.toString();
          _plan = json['plan']?.toString() ?? 'free';
          _usedToday = (json['used_today'] as num?)?.toInt() ?? 0;
          _dailyLimit = (json['daily_limit'] as num?)?.toInt() ?? 5;
          _errorMessage = (json['status'] == 'error') ? json['message']?.toString() : null;
          if (json['apps'] is List) {
            _apps = List<Map<String, dynamic>>.from(
              (json['apps'] as List).where((e) => e is Map).map((e) => Map<String, dynamic>.from(e)),
            );
            _apps.sort((a, b) => (a['sort_order'] ?? 99).compareTo(b['sort_order'] ?? 99));
          }
        });
      }
    } catch (e) {
      setState(() { _errorMessage = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    } catch (_) { return d; }
  }

  Map<String, List<Map<String, dynamic>>> _grouped() {
    final m = <String, List<Map<String, dynamic>>>{};
    for (final a in _apps) { m.putIfAbsent(a['category']?.toString() ?? 'อื่นๆ', () => []).add(a); }
    return m;
  }

  Future<void> _onAppTap(Map<String, dynamic> app) async {
    if (_isAppLoading) return;
    final appId = (app['id'] as num?)?.toInt() ?? 0;
    final appName = app['name']?.toString() ?? 'App';
    final iconUrl = app['icon_url']?.toString() ?? '';
    final targetUrl = app['target_url']?.toString() ?? '';

    // Navigate to in-app webview page
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _InAppWebViewPage(
        appId: appId,
        appName: appName,
        appIconUrl: iconUrl,
        fallbackUrl: targetUrl,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.getBackGround(context),
      appBar: AppBar(
        backgroundColor: ColorUtils.getBackGround(context),
        surfaceTintColor: Colors.transparent, elevation: 0,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Styles.primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.apps, color: Styles.primaryColor, size: 22)),
          const SizedBox(width: 10),
          Text('เครื่องมือ', style: Styles.textStyle.copyWith(fontSize: 22, color: ColorUtils.getPrimaryText(context), fontWeight: FontWeight.bold)),
        ]),
        centerTitle: true,
      ),
      body: RefreshIndicator(onRefresh: _fetchApps, color: Styles.primaryColor, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _apps.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('กำลังดึงข้อมูล...', style: TextStyle(color: Colors.grey))]));
    if (_errorMessage != null && _apps.isEmpty) return _buildError();
    final g = _grouped();
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), children: [
      _buildStatus(), const SizedBox(height: 16),
      ...g.entries.map((e) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _catHeader(e.key, e.value.length), const SizedBox(height: 10), _grid(e.value), const SizedBox(height: 16),
      ])),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildStatus() {
    final on = _apps.isNotEmpty && _errorMessage == null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: on ? [const Color(0xFF1BA0E1), const Color(0xFF0D7EC0)] : [Colors.grey[700]!, Colors.grey[800]!]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: (on ? const Color(0xFF1BA0E1) : Colors.grey).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
            child: Icon(on ? Icons.cloud_done : Icons.cloud_off, color: Colors.white, size: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(on ? 'OTP24 พร้อมใช้งาน' : 'ไม่สามารถเชื่อมต่อได้', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(on ? '${_plan?.toUpperCase()} • ${_apps.length} แอพ • ${_fmtDate(_updatedAt)}' : _errorMessage ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
          _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : IconButton(onPressed: _fetchApps, icon: const Icon(Icons.refresh, color: Colors.white)),
        ]),
        if (on) ...[
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
            value: _dailyLimit > 0 ? _usedToday / _dailyLimit : 0,
            backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(_usedToday >= _dailyLimit ? Colors.red[300]! : Colors.white), minHeight: 4)),
          const SizedBox(height: 6),
          Text('ใช้ไป: $_usedToday / $_dailyLimit ครั้ง', style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ]),
    );
  }

  Widget _catHeader(String cat, int n) {
    final dn = {'streaming':'🎬 สตรีมมิ่ง','social':'👥 โซเชียล','music':'🎵 เพลง','tools':'🛠 เครื่องมือ',
      'education':'📚 การศึกษา','design':'🎨 ดีไซน์','ai':'🤖 AI','vpn':'🔒 VPN'}[cat.toLowerCase()] ?? '📦 $cat';
    final c = {'streaming':Colors.red,'social':Colors.blue,'music':Colors.green,'tools':Colors.orange,
      'education':Colors.purple,'design':Colors.pink,'ai':Colors.teal,'vpn':Colors.indigo}[cat.toLowerCase()] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Text(dn, style: Styles.textStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: ColorUtils.getPrimaryText(context))),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Text('$n', style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _grid(List<Map<String, dynamic>> apps) => GridView.builder(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.78, crossAxisSpacing: 10, mainAxisSpacing: 10),
    itemCount: apps.length,
    itemBuilder: (ctx, i) {
      final a = apps[i]; final locked = a['is_locked'] == true;
      final name = a['name']?.toString() ?? 'App'; final icon = a['icon_url']?.toString() ?? '';
      return GestureDetector(
        onTap: () {
          if (locked) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🔒 ${a['requirement'] ?? "Premium"}'), backgroundColor: Colors.orange[700], behavior: SnackBarBehavior.floating)); }
          else { _onAppTap(a); }
        },
        child: Opacity(opacity: locked ? 0.5 : 1, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(children: [
            Container(width: 56, height: 56,
              decoration: BoxDecoration(color: ColorUtils.getCardColor(context), borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))]),
              clipBehavior: Clip.antiAlias,
              child: icon.isNotEmpty ? Image.network(icon, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.apps, size: 28, color: Colors.grey)) : const Icon(Icons.apps, size: 28, color: Colors.grey)),
            if (locked) Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle), child: const Icon(Icons.lock, size: 10, color: Colors.white))),
          ]),
          const SizedBox(height: 6),
          Text(name, style: Styles.textStyle.copyWith(fontSize: 10, color: ColorUtils.getPrimaryText(context)), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ])),
      );
    },
  );

  Widget _buildError() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
    const SizedBox(height: 16),
    Text('ไม่สามารถเชื่อมต่อ OTP24 ได้', style: Styles.textStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: ColorUtils.getPrimaryText(context))),
    const SizedBox(height: 8),
    Text(_errorMessage ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[500]), textAlign: TextAlign.center),
    const SizedBox(height: 24),
    ElevatedButton.icon(onPressed: _fetchApps, icon: const Icon(Icons.refresh), label: const Text('ลองอีกครั้ง'),
      style: ElevatedButton.styleFrom(backgroundColor: Styles.primaryColor, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
  ])));
}

// ─── In-App WebView Page ──────────────────────────
class _InAppWebViewPage extends StatefulWidget {
  final int appId;
  final String appName;
  final String appIconUrl;
  final String fallbackUrl;

  const _InAppWebViewPage({
    required this.appId,
    required this.appName,
    required this.appIconUrl,
    required this.fallbackUrl,
  });

  @override
  State<_InAppWebViewPage> createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<_InAppWebViewPage> {
  bool _isLoading = true;
  String _status = 'กำลังค้นหาเซิร์ฟเวอร์...';
  String? _error;
  Webview? _webview;
  String? _currentUrl;
  bool _webviewOpen = false;

  @override
  void initState() {
    super.initState();
    _autoFetch();
  }

  @override
  void dispose() {
    if (_webview != null) {
      try { _webview!.close(); } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _autoFetch() async {
    setState(() { _isLoading = true; _error = null; _status = 'กำลังค้นหาเซิร์ฟเวอร์...'; });
    try {
      final prov = Provider.of<TradingProvider>(context, listen: false);

      // 1. Get nodes
      final np = jsonDecode(await prov.fetchOtp24Nodes(widget.appId));
      List<Map<String, dynamic>> nodes = [];
      if (np is List) {
        nodes = List<Map<String, dynamic>>.from(np.where((e) => e is Map).map((e) => Map<String, dynamic>.from(e)));
      } else if (np is Map && np['status'] == 'error') {
        throw Exception(np['message']?.toString() ?? 'ดึงเซิร์ฟเวอร์ไม่ได้');
      }

      final ok = nodes.where((n) =>
        (n['is_working'] == true || n['is_working'] == 1) &&
        (n['can_access'] == true || n['can_access'] == 1)
      ).toList();
      if (ok.isEmpty) throw Exception('ไม่พบเซิร์ฟเวอร์ที่ใช้งานได้');

      final nodeId = (ok.first['id'] as num?)?.toInt() ?? 0;
      setState(() { _status = 'กำลังดึง Cookie...'; });

      // 2. Fetch cookie
      final cp = jsonDecode(await prov.fetchOtp24Cookie(nodeId));
      String openUrl = widget.fallbackUrl;
      List<Map<String, dynamic>> cookies = [];
      if (cp is Map<String, dynamic>) {
        openUrl = cp['target_url']?.toString() ?? widget.fallbackUrl;
        if (cp['status'] == 'error') throw Exception(cp['message']?.toString() ?? 'ดึง Cookie ไม่สำเร็จ');
        if (cp['cookies'] is List) {
          cookies = List<Map<String, dynamic>>.from(
            (cp['cookies'] as List).where((e) => e is Map).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }

      setState(() { _status = 'กำลังเปิด ${widget.appName}...'; _currentUrl = openUrl; });

      // 3. Open WebView
      final wv = await WebviewWindow.create(
        configuration: CreateConfiguration(
          title: widget.appName,
          windowWidth: 1280,
          windowHeight: 800,
          titleBarTopPadding: 0,
        ),
      );
      _webview = wv;
      _webviewOpen = true;

      // Cookie injection script  
      final js = cookies.map((c) {
        final n = _e(c['name']?.toString() ?? '');
        final v = _e(c['value']?.toString() ?? '').replaceAll(';', '%3B');
        final p = c['path']?.toString() ?? '/';
        final s = (c['secure'] == true) ? '; Secure' : '';
        var exp = '';
        final ed = c['ExpiresDate'] ?? c['expirationDate'];
        if (ed is num) {
          exp = '; expires=${DateTime.fromMillisecondsSinceEpoch((ed * 1000).toInt()).toUtc().toIso8601String()}';
        }
        return "document.cookie='$n=$v; path=$p$exp$s';";
      }).join('\n');

      if (js.isNotEmpty) {
        wv.addScriptToExecuteOnDocumentCreated(js);
      }

      // Listen for URL changes
      wv.addOnUrlRequestCallback((url) {
        if (mounted) setState(() { _currentUrl = url; });
      });

      // When webview closes, go back
      wv.onClose.then((_) {
        _webviewOpen = false;
        if (mounted) Navigator.of(context).pop();
      });

      wv.launch(openUrl);
      setState(() { _isLoading = false; });

    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  String _e(String s) => s.replaceAll("'", "\\'");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.getBackGround(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1BA0E1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_webview != null && _webviewOpen) {
              try { _webview!.close(); } catch (_) {}
            }
            Navigator.of(context).pop();
          },
        ),
        title: Row(children: [
          if (widget.appIconUrl.isNotEmpty)
            ClipRRect(borderRadius: BorderRadius.circular(6),
              child: Image.network(widget.appIconUrl, width: 24, height: 24, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(widget.appName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            if (_currentUrl != null)
              Text(_currentUrl!, style: const TextStyle(color: Colors.white70, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
        actions: [
          if (_webview != null && !_isLoading) ...[
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () { _webview?.reload(); }),
            IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18), onPressed: () { _webview?.back(); }),
            IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18), onPressed: () { _webview?.forward(); }),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(height: 24),
              if (widget.appIconUrl.isNotEmpty)
                Padding(padding: const EdgeInsets.only(bottom: 16), child: ClipRRect(borderRadius: BorderRadius.circular(16),
                  child: Image.network(widget.appIconUrl, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()))),
              Text(widget.appName, style: Styles.textStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: ColorUtils.getPrimaryText(context))),
              const SizedBox(height: 12),
              Text(_status, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ]))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
                  const SizedBox(height: 14),
                  Text('เปิด ${widget.appName} ไม่สำเร็จ', style: Styles.textStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: ColorUtils.getPrimaryText(context))),
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(fontSize: 13, color: Colors.grey[500]), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(onPressed: _autoFetch, icon: const Icon(Icons.refresh), label: const Text('ลองอีกครั้ง'),
                    style: ElevatedButton.styleFrom(backgroundColor: Styles.primaryColor, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                ])))
              // WebView is open in separate window — show info panel
              : Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_new, size: 64, color: Styles.primaryColor.withOpacity(0.5)),
                      const SizedBox(height: 20),
                      Text('${widget.appName} กำลังแสดงอยู่', style: Styles.textStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: ColorUtils.getPrimaryText(context))),
                      const SizedBox(height: 8),
                      Text('สลับไปที่หน้าต่าง ${widget.appName} เพื่อใช้งาน\nปิดหน้าต่างเพื่อกลับมาที่นี่', style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            if (_webview != null && _webviewOpen) {
                              try { _webview!.close(); } catch (_) {}
                            }
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('กลับ'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ]),
                    ],
                  ),
                ),
    );
  }
}
