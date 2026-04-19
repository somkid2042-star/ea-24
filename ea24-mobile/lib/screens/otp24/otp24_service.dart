import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// OTP24 Service — handles all communication with EA-Server for OTP24 features
/// All credentials (device_id, license_key) are stored in the server's DB only.
class OTP24Service {
  static const String _defaultServerBase = 'http://35.201.156.240:4173';
  static const String _serverIpKey = 'otp24_server_ip';

  // ─── Server IP Management ─────────────────────────
  static Future<String> getServerBase() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(_serverIpKey);
    if (ip != null && ip.isNotEmpty) {
      String base = ip.startsWith('http') ? ip : 'http://$ip';
      final uri = Uri.tryParse(base);
      if (uri != null && !uri.hasPort) {
        base = '${uri.scheme}://${uri.host}:4173';
      }
      return base;
    }
    return _defaultServerBase;
  }

  static Future<void> setServerBase(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverIpKey, ip.trim());
  }

  static Future<String> getSavedServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverIpKey) ?? '';
  }

  // ─── Admin Force Update Settings ───────────────────
  static Future<Map<String, dynamic>> updateAdminSettings(String deviceId, String licenseKey) async {
    final serverBase = await getServerBase();
    try {
      final res = await http.post(
        Uri.parse('$serverBase/api/otp24/admin_settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
          'license_key': licenseKey,
        }),
      ).timeout(const Duration(seconds: 10));

      final body = res.body.trim();
      if (body.startsWith('<')) {
        return {'status': 'error', 'message': 'Server ยังไม่รองรับ (อาจต้องอัพเดท)'};
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('OTP24 updateAdminSettings error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Fetch Account Info from EA-Server ─────────────
  static Future<Map<String, dynamic>> fetchAccountInfo() async {
    final serverBase = await getServerBase();
    try {
      final res = await http.get(
        Uri.parse('$serverBase/api/otp24/account_info'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('OTP24 fetchAccountInfo error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Fetch Apps List ──────────────────────────────
  static Future<Map<String, dynamic>> fetchApps() async {
    final serverBase = await getServerBase();
    try {
      final res = await http.get(
        Uri.parse('$serverBase/api/otp24/account_info'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data.containsKey('apps') && data['apps'] is List) {
        return data;
      }

      // Cache stale — force fresh fetch
      debugPrint('OTP24: Cache stale, force fetching via /api/cookies...');
      final freshRes = await http.get(
        Uri.parse('$serverBase/api/cookies'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      return jsonDecode(freshRes.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('OTP24 fetchApps error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Fetch Nodes via EA-Server Proxy ────────────────
  static Future<dynamic> fetchNodes(int appId) async {
    final cached = await _getLocal('nodes_$appId');
    if (cached != null && cached is List) return cached;

    final serverBase = await getServerBase();
    try {
      final res = await http.get(
        Uri.parse('$serverBase/api/otp24/nodes?app_id=$appId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      debugPrint('OTP24 fetchNodes status=${res.statusCode}');
      final data = _parseServerResponse(res.body);

      if (data is List) {
        _saveLocal('nodes_$appId', data);
        _saveToServer('nodes_$appId', data);
        return data;
      }
      if (data is Map && data['nodes'] is List) {
        _saveLocal('nodes_$appId', data['nodes']);
        return data['nodes'];
      }
      return data;
    } catch (e) {
      if (cached != null) return cached;
      debugPrint('OTP24 fetchNodes error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Fetch Cookie via EA-Server Proxy ──────────────
  static Future<dynamic> fetchCookie(dynamic nodeId, {bool force = false, int? appId}) async {
    final cacheKey = 'cookie_app${appId ?? 0}_node$nodeId';

    if (!force) {
      final cached = await _getLocal(cacheKey);
      if (cached != null) {
        debugPrint('OTP24: Using cached cookie for node $nodeId');
        return cached;
      }
    }

    final serverBase = await getServerBase();
    try {
      final res = await http.get(
        Uri.parse('$serverBase/api/otp24/cookie?node_id=$nodeId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      debugPrint('OTP24 fetchCookie status=${res.statusCode}');
      final data = _parseServerResponse(res.body);

      _saveLocal(cacheKey, data);
      _saveToServer(cacheKey, data);
      if (appId != null) await _markAppCached(appId);
      return data;
    } catch (e) {
      final cached = await _getLocal(cacheKey);
      if (cached != null) return cached;
      debugPrint('OTP24 fetchCookie error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Parse Server Response ────────────────────────
  /// Server should return decoded JSON directly.
  /// If it returns {success, payload}, try to decode payload.
  static dynamic _parseServerResponse(String body) {
    final parsed = jsonDecode(body);
    if (parsed is Map && parsed['payload'] is String && parsed['success'] == true) {
      // Server returned raw payload — return as-is for error display
      return parsed;
    }
    return parsed;
  }

  // ─── Local Cache (SharedPreferences) ──────────────
  static Future<void> _saveLocal(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('otp24_cache_$key', jsonEncode(data));
  }

  static Future<dynamic> _getLocal(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('otp24_cache_$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _markAppCached(int appId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('otp24_cached_app_ids') ?? [];
    final idStr = appId.toString();
    if (!ids.contains(idStr)) {
      ids.add(idStr);
      await prefs.setStringList('otp24_cached_app_ids', ids);
    }
  }

  // ─── Server Save (fire-and-forget backup) ─────────
  static Future<void> _saveToServer(String key, dynamic data) async {
    final serverBase = await getServerBase();
    try {
      await http.post(
        Uri.parse('$serverBase/api/otp24/save_cookie'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cache_key': key, 'payload': data}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('OTP24 saveToServer error: $e');
    }
  }

  // ─── Get Cached App IDs + Status ──────────────────
  static Future<Map<int, String>> fetchCachedAppStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('otp24_cached_app_ids') ?? [];
    final Map<int, String> result = {};
    for (final idStr in ids) {
      final appId = int.tryParse(idStr);
      if (appId != null) {
        result[appId] = 'valid';
      }
    }
    return result;
  }

  static Future<List<int>> fetchCachedAppIds() async {
    final status = await fetchCachedAppStatus();
    return status.keys.toList();
  }
}
