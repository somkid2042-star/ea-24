import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// OTP24 Service — handles all communication with EA-Server for OTP24 features
class OTP24Service {
  static const String _defaultServerBase = 'http://35.201.156.240:4173';
  static const String _secretKey = 'OTP24HRHUB_PROTECT';
  static const String _serverIpKey = 'otp24_server_ip';

  // ─── Server IP Management ─────────────────────────
  static Future<String> getServerBase() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(_serverIpKey);
    if (ip != null && ip.isNotEmpty) {
      String base = ip.startsWith('http') ? ip : 'http://$ip';
      // ถ้าไม่ได้ระบุ port → ใส่ :4173 ให้อัตโนมัติ
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
    final serverBase = await getServerBase();
    try {
      final res = await http.post(
        Uri.parse('$serverBase/api/otp24/sync_device'),
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

      // ตรวจสอบว่า response เป็น JSON หรือไม่ (server เก่าอาจส่ง HTML กลับ)
      final body = res.body.trim();
      if (body.startsWith('<') || body.startsWith('<!')) {
        return {
          'status': 'error',
          'message': 'Server ยังไม่รองรับฟังก์ชันนี้ (อาจต้องอัพเดท Server)',
        };
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
      // First try account_info (uses cache)
      final res = await http.get(
        Uri.parse('$serverBase/api/otp24/account_info'),
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
        Uri.parse('$serverBase/api/cookies'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      return jsonDecode(freshRes.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('OTP24 fetchApps error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── XOR Decode Helper (matches server SECRET_KEY) ──
  static String _xorDecode(String encoded) {
    const key = 'OTP24HRHUB_PROTECT';
    final bytes = base64.decode(encoded);
    final keyBytes = utf8.encode(key);
    final decoded = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return utf8.decode(decoded);
  }

  static dynamic _safeJsonDecode(String body) {
    try {
      final parsed = jsonDecode(body);
      // Check if it's an otp24hr wrapper: {"success":true, "payload":"..."}
      if (parsed is Map && parsed['payload'] is String && parsed['success'] == true) {
        final payloadStr = parsed['payload'] as String;
        try {
          // Try XOR decode the payload
          final decoded = _xorDecode(payloadStr);
          return jsonDecode(decoded);
        } catch (_) {
          // Payload might be plain JSON
          try {
            return jsonDecode(payloadStr);
          } catch (_) {
            // Return the wrapper as-is
            return parsed;
          }
        }
      }
      return parsed;
    } catch (_) {
      // Body might be XOR-encoded directly
      try {
        final decoded = _xorDecode(body.trim());
        return jsonDecode(decoded);
      } catch (e2) {
        throw FormatException('Cannot parse response: ${body.substring(0, body.length.clamp(0, 50))}');
      }
    }
  }

  // ─── OTP24HR Direct API ─────────────────────────────
  static const String _otp24hrApi = 'https://otp24hr.com/api/v1/tools/api';

  /// Get credentials from ea-server's cached account_info
  static Future<Map<String, String>> _getCredentials() async {
    final serverBase = await getServerBase();
    final res = await http.get(
      Uri.parse('$serverBase/api/otp24/account_info'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body);
    return {
      'csrf_token': data['csrf_token']?.toString() ?? '',
      'device_id': data['device_id']?.toString() ?? '',
      'license_key': data['license_key']?.toString() ?? '',
    };
  }

  /// Call otp24hr API directly
  static Future<dynamic> _callOtp24hrDirect(String action, Map<String, String> params) async {
    final creds = await _getCredentials();
    final csrf = creds['csrf_token']!;
    final deviceId = creds['device_id']!;
    final licenseKey = creds['license_key']!;

    final queryParams = {
      'action': action,
      'key': licenseKey,
      ...params,
    };
    final uri = Uri.parse(_otp24hrApi).replace(queryParameters: queryParams);

    final res = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'x-csrf-token': csrf,
      'x-device-id': deviceId, 
      'x-license-key': licenseKey,
    }).timeout(const Duration(seconds: 15));

    debugPrint('OTP24 [$action] status=${res.statusCode} body=${res.body.substring(0, res.body.length.clamp(0, 80))}');

    final json = jsonDecode(res.body);
    if (json['success'] != true) {
      throw Exception(json['message']?.toString() ?? 'API call failed');
    }

    final payload = json['payload']?.toString() ?? '';
    if (payload.isEmpty) {
      throw Exception('No payload in response');
    }

    // Try multiple decode strategies
    // 1. XOR decode with OTP24HRHUB_PROTECT
    try {
      final decoded = _xorDecode(payload);
      final result = jsonDecode(decoded);
      debugPrint('OTP24 [$action] XOR decode OK');
      return result;
    } catch (_) {}

    // 2. Plain base64 decode (no XOR)
    try {
      final bytes = base64.decode(payload);
      final decoded = utf8.decode(bytes);
      final result = jsonDecode(decoded);
      debugPrint('OTP24 [$action] base64 decode OK');
      return result;
    } catch (_) {}

    // 3. Payload is plain JSON string
    try {
      final result = jsonDecode(payload);
      debugPrint('OTP24 [$action] plain JSON OK');
      return result;
    } catch (_) {}

    // 4. Return raw wrapper if nothing works
    debugPrint('OTP24 [$action] all decode failed, returning wrapper');
    return json;
  }

  // ─── Fetch Nodes via EA-Server Proxy ────────────────
  static Future<dynamic> fetchNodes(int appId) async {
    // Try local cache first
    final cached = await _getLocal('nodes_$appId');
    if (cached != null && cached is List) return cached;

    final serverBase = await getServerBase();
    try {
      final res = await http.get(
        Uri.parse('$serverBase/api/otp24/nodes?app_id=$appId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      debugPrint('OTP24 fetchNodes status=${res.statusCode}');
      final data = _safeJsonDecode(res.body);
      
      // Server returns decoded nodes array or error
      if (data is List) {
        _saveLocal('nodes_$appId', data);
        _saveToServer('nodes_$appId', data);
        return data;
      }
      // Might be wrapped: {"status":"success","nodes":[...]}
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
      final data = _safeJsonDecode(res.body);
      
      // Save to local + server cache
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
  /// Returns map: {appId: 'valid'}
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

  /// Legacy: returns just the list of app IDs
  static Future<List<int>> fetchCachedAppIds() async {
    final status = await fetchCachedAppStatus();
    return status.keys.toList();
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
}
