import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Position {
  final int ticket;
  final String symbol;
  final String type; // "BUY" or "SELL"
  final double volume;
  final double openPrice;
  final double currentPrice;
  final double profit;
  final double sl;
  final double tp;
  final String comment;

  Position({
    required this.ticket,
    required this.symbol,
    required this.type,
    required this.volume,
    required this.openPrice,
    required this.currentPrice,
    required this.profit,
    required this.sl,
    required this.tp,
    required this.comment,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    final typeInt = json['type'];
    String typeStr;
    if (typeInt is int) {
      typeStr = typeInt == 0 ? 'BUY' : 'SELL';
    } else {
      typeStr = typeInt?.toString() ?? 'UNKNOWN';
    }
    return Position(
      ticket: (json['ticket'] ?? 0) is int
          ? json['ticket']
          : int.tryParse(json['ticket'].toString()) ?? 0,
      symbol: json['symbol'] ?? '',
      type: typeStr,
      volume: (json['volume'] ?? json['lots'] ?? 0.0).toDouble(),
      openPrice:
          (json['open_price'] ?? json['price_open'] ?? 0.0).toDouble(),
      currentPrice:
          (json['current_price'] ?? json['price_current'] ?? 0.0).toDouble(),
      profit: (json['pnl'] ?? json['profit'] ?? 0.0).toDouble(),
      sl: (json['sl'] ?? 0.0).toDouble(),
      tp: (json['tp'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
    );
  }
}

class PipelineResult {
  final String symbol;
  final String decision;
  final double confidence;
  final String reasoning;
  final String strategyName;
  final String timeframe;
  final DateTime time;

  PipelineResult({
    required this.symbol,
    required this.decision,
    required this.confidence,
    required this.reasoning,
    required this.strategyName,
    required this.timeframe,
    required this.time,
  });
}

class AgentLog {
  final String symbol;
  final String agent;
  final String status;
  final String message;
  final DateTime time;

  AgentLog({
    required this.symbol,
    required this.agent,
    required this.status,
    required this.message,
    required this.time,
  });
}

class TradingProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  String _serverUrl = 'ws://localhost:8080';
  bool _isConnected = false;
  bool _eaConnected = false;
  String _eaVersion = 'unknown';

  double _balance = 0;
  double _equity = 0;
  double _totalProfit = 0;
  int _openPositionCount = 0;
  List<Position> _positions = [];
  List<PipelineResult> _pipelineResults = [];
  List<AgentLog> _agentLogs = [];
  bool _autoAnalyzeEnabled = false;
  List<Map<String, dynamic>> _autopilotJobs = [];

  // Notification callback
  Function(String title, String body)? onNotification;

  // Getters
  String get serverUrl => _serverUrl;
  bool get isConnected => _isConnected;
  bool get eaConnected => _eaConnected;
  String get eaVersion => _eaVersion;
  double get balance => _balance;
  double get equity => _equity;
  double get totalProfit => _totalProfit;
  int get openPositionCount => _openPositionCount;
  List<Position> get positions => List.unmodifiable(_positions);
  List<PipelineResult> get pipelineResults =>
      List.unmodifiable(_pipelineResults);
  List<AgentLog> get agentLogs => List.unmodifiable(_agentLogs);
  bool get autoAnalyzeEnabled => _autoAnalyzeEnabled;
  List<Map<String, dynamic>> get autopilotJobs =>
      List.unmodifiable(_autopilotJobs);

  double get drawdownPercent {
    if (_balance <= 0) return 0;
    return ((_balance - _equity) / _balance * 100).clamp(0, 100);
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('server_url') ?? 'ws://localhost:8080';
    connect();
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    _serverUrl = url;
    disconnect();
    connect();
    notifyListeners();
  }

  void connect() {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      _isConnected = true;
      notifyListeners();

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (error) {
          debugPrint('WS Error: $error');
          _onDisconnect();
        },
        onDone: () {
          _onDisconnect();
        },
      );

      // Send initial handshake
      _send({'action': 'get_status'});

      // Periodic ping
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _send({'action': 'ping'});
      });
    } catch (e) {
      debugPrint('WS Connect Error: $e');
      _onDisconnect();
    }
  }

  void _onDisconnect() {
    _isConnected = false;
    _eaConnected = false;
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _pingTimer?.cancel();
    notifyListeners();

    // Auto-reconnect after 5 seconds
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _eaConnected = false;
    notifyListeners();
  }

  void _send(Map<String, dynamic> data) {
    if (_channel != null) {
      try {
        _channel!.sink.add(json.encode(data));
      } catch (e) {
        debugPrint('WS Send Error: $e');
      }
    }
  }

  void _onMessage(dynamic rawData) {
    try {
      final data = json.decode(rawData as String);
      if (data is! Map<String, dynamic>) return;

      final type = data['type'] as String?;
      final action = data['action'] as String?;

      // EA status update
      if (type == 'ea_status' || type == 'status') {
        _eaConnected = data['connected'] == true;
        _eaVersion = data['version']?.toString() ?? _eaVersion;
        notifyListeners();
      }

      // Account data update
      if (type == 'account_data' || type == 'account_update') {
        _balance = (data['balance'] ?? _balance).toDouble();
        _equity = (data['equity'] ?? _equity).toDouble();
        _openPositionCount = data['open_positions'] ?? _openPositionCount;

        if (data['positions'] != null && data['positions'] is List) {
          _positions = (data['positions'] as List)
              .map((p) => Position.fromJson(p as Map<String, dynamic>))
              .toList();
          _openPositionCount = _positions.length;
          _totalProfit = _positions.fold(0.0, (sum, p) => sum + p.profit);
        }
        notifyListeners();
      }

      // Pipeline result
      if (type == 'pipeline_result') {
        final result = data['result'];
        if (result != null) {
          _pipelineResults.insert(
            0,
            PipelineResult(
              symbol: data['symbol'] ?? '',
              decision: result['decision'] ?? 'HOLD',
              confidence: (result['confidence'] ?? 0.0).toDouble(),
              reasoning: result['reasoning'] ?? '',
              strategyName: result['strategy_name'] ?? '',
              timeframe: result['timeframe'] ?? '',
              time: DateTime.now(),
            ),
          );
          if (_pipelineResults.length > 50) {
            _pipelineResults = _pipelineResults.sublist(0, 50);
          }

          // Trigger notification for trade signals
          final decision = result['decision'] ?? 'HOLD';
          if (decision == 'BUY' || decision == 'SELL') {
            onNotification?.call(
              '${decision == 'BUY' ? '🟢' : '🔴'} $decision Signal',
              '${data['symbol']} — ${result['strategy_name']} (${(result['confidence'] ?? 0).toStringAsFixed(0)}%)',
            );
          }
          notifyListeners();
        }
      }

      // Agent log
      if (type == 'agent_log') {
        _agentLogs.insert(
          0,
          AgentLog(
            symbol: data['symbol'] ?? '',
            agent: data['agent'] ?? '',
            status: data['status'] ?? '',
            message: data['message'] ?? '',
            time: DateTime.now(),
          ),
        );
        if (_agentLogs.length > 100) {
          _agentLogs = _agentLogs.sublist(0, 100);
        }
        notifyListeners();
      }

      // Position manage result
      if (type == 'position_manage_result') {
        onNotification?.call(
          'Position Manager',
          '${data['symbol']} — ${data['position_count']} positions managed',
        );
        notifyListeners();
      }

      // News avoidance
      if (type == 'news_avoidance') {
        onNotification?.call(
          'News Alert',
          data['message'] ?? 'High-impact news detected',
        );
        _agentLogs.insert(
          0,
          AgentLog(
            symbol: data['symbol'] ?? '',
            agent: 'news_engine',
            status: 'warning',
            message: data['message'] ?? '',
            time: DateTime.now(),
          ),
        );
        notifyListeners();
      }

      // Market closed
      if (type == 'market_closed') {
        _agentLogs.insert(
          0,
          AgentLog(
            symbol: data['symbol'] ?? '',
            agent: 'autopilot',
            status: 'info',
            message: data['message'] ?? 'Market closed',
            time: DateTime.now(),
          ),
        );
        notifyListeners();
      }

      // Config updates
      if (type == 'config_update' || type == 'config') {
        if (data['key'] == 'ai_auto_analyze') {
          _autoAnalyzeEnabled = data['value'] == 'true';
          notifyListeners();
        }
        if (data['key'] == 'ai_autopilot_jobs') {
          try {
            _autopilotJobs = List<Map<String, dynamic>>.from(
                json.decode(data['value'] ?? '[]'));
          } catch (_) {}
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('WS Parse Error: $e');
    }
  }

  // ── Trading Commands ──────────────────────────

  void closeTrade(int ticket) {
    _send({'action': 'close_trade', 'ticket': ticket});
    onNotification?.call(
        'Order Sent', 'Close request sent for ticket #$ticket');
  }

  void openTrade(String symbol, String direction, double lotSize) {
    _send({
      'action': 'open_trade',
      'symbol': symbol,
      'direction': direction,
      'lot_size': lotSize,
      'comment': 'EA24-Mobile',
    });
    onNotification?.call(
        'Order Sent', '$direction $symbol lot: $lotSize');
  }

  void toggleAutoAnalyze(bool enabled) {
    _send({
      'action': 'set_config',
      'config_key': 'ai_auto_analyze',
      'config_value': enabled.toString(),
    });
    _autoAnalyzeEnabled = enabled;
    notifyListeners();
  }

  Future<String> fetchOtp24Cookies() async {
    try {
      final httpUrl = _serverUrl.replaceFirst('ws', 'http');
      final host = Uri.parse(httpUrl).host;
      final uri = Uri.parse('http://$host:4173/api/cookies');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception("Server unavailable: $e");
    }
  }

  Future<String> fetchOtp24Nodes(int appId) async {
    try {
      final httpUrl = _serverUrl.replaceFirst('ws', 'http');
      final host = Uri.parse(httpUrl).host;
      final uri = Uri.parse('http://$host:4173/api/otp24/nodes?app_id=$appId');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Server Error ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("$e");
    }
  }

  Future<String> fetchOtp24Cookie(int nodeId) async {
    try {
      final httpUrl = _serverUrl.replaceFirst('ws', 'http');
      final host = Uri.parse(httpUrl).host;
      final uri = Uri.parse('http://$host:4173/api/otp24/cookie?node_id=$nodeId');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Server Error ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("$e");
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
