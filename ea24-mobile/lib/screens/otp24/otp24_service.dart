import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// OTP24 Service — handles all communication with EA-Server for OTP24 features
class OTP24Service {
  static const String _eaServerBase = 'http://localhost:4173';
  static const String _secretKey = 'OTP24HRHUB_PROTECT';

  // ─── Device ID ─────────────────────────────────────
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('otp24_device_id');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _generateFingerprint();
      await prefs.setString('otp24_device_id', deviceId);
    }
    return deviceId;
  }

  static String _generateFingerprint() {
    final now = DateTime.now();
    final platform = defaultTargetPlatform.name;
    final tz = now.timeZoneName;
    final raw = 'OTP|flutter|$platform|$tz|${now.microsecondsSinceEpoch}';
    return base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
  }

  // ─── Sync Device ID to EA-Server (One-time DB lock) ───
  static Future<Map<String, dynamic>> syncDeviceId({
    String? csrfToken,
    String? licenseKey,
  }) async {
    final deviceId = await getDeviceId();
    try {
      final res = await http.post(
        Uri.parse('$_eaServerBase/api/otp24/sync_device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
          'csrf_token': csrfToken ?? '',
          'license_key': licenseKey ?? '',
        }),
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      
      // If 403 Forbidden (already locked), treat as successful sync state
      if (res.statusCode == 403) {
        return {'status': 'success', 'message': data['message'] ?? 'Device ID is already locked'};
      }
      return data;
    } catch (e) {
      debugPrint('OTP24 syncDeviceId error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Admin Force Update Settings ───────────────────
  static Future<Map<String, dynamic>> updateAdminSettings(String deviceId, String licenseKey) async {
    try {
      final res = await http.post(
        Uri.parse('$_eaServerBase/api/otp24/admin_settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
          'license_key': licenseKey,
        }),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('OTP24 updateAdminSettings error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }


  // ─── Fetch Account Info from EA-Server ─────────────
  static Future<Map<String, dynamic>> fetchAccountInfo() async {
    try {
      final res = await http.get(
        Uri.parse('$_eaServerBase/api/otp24/account_info'),
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
    try {
      // First try account_info (uses cache)
      final res = await http.get(
        Uri.parse('$_eaServerBase/api/otp24/account_info'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      // If response has 'apps' list, it's valid data
      if (data.containsKey('apps') && data['apps'] is List) {
        return data;
      }

      // Cache is stale/placeholder — force fetch fresh data from OTP24HR
      debugPrint('OTP24: Cache stale (no apps key), force fetching via /api/cookies...');
      final freshRes = await http.get(
        Uri.parse('$_eaServerBase/api/cookies'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      return jsonDecode(freshRes.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('OTP24 fetchApps error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Fetch Nodes for an App ────────────────────────
  static Future<dynamic> fetchNodes(int appId) async {
    try {
      final res = await http.get(
        Uri.parse('$_eaServerBase/api/otp24/nodes?app_id=$appId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('OTP24 fetchNodes error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Fetch Cookie for a Node ───────────────────────
  static Future<dynamic> fetchCookie(dynamic nodeId, {bool force = false}) async {
    try {
      final url = '$_eaServerBase/api/otp24/cookie?node_id=$nodeId${force ? '&force=true' : ''}';
      final res = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('OTP24 fetchCookie error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── Get Cached App IDs ────────────────────────────
  static Future<List<int>> fetchCachedAppIds() async {
    try {
      final res = await http.get(
        Uri.parse('$_eaServerBase/api/otp24/cached_apps'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['cached_app_ids'] is List) {
        return (data['cached_app_ids'] as List).map((e) => (e as num).toInt()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── XOR Decode ────────────────────────────────────
  static String? xorDecode(String encodedStr, [String key = _secretKey]) {
    try {
      final bytes = base64.decode(encodedStr);
      final keyBytes = utf8.encode(key);
      final decoded = List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
      );
      return utf8.decode(decoded);
    } catch (e) {
      debugPrint('XOR decode error: $e');
      return null;
    }
  }

  // ─── Save Session to Server ────────────────────────
  static Future<void> saveSession({
    required String nodeId,
    required List<Map<String, dynamic>> cookies,
    required String targetUrl,
    String? csrfToken,
    String? licenseKey,
  }) async {
    try {
      final deviceId = await getDeviceId();
      await http.post(
        Uri.parse('$_eaServerBase/api/otp24/save_cookie'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'node_id': nodeId,
          'cookies': cookies,
          'target_url': targetUrl,
          'device_id': deviceId,
          'csrf_token': csrfToken ?? '',
          'license_key': licenseKey ?? '',
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('OTP24 saveSession error: $e');
    }
  }
}
