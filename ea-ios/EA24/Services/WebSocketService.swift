import Foundation

/// WebSocket service connecting to ea-server
class WebSocketService: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {
    private let host: String
    private let port: String
    private weak var state: TradingState?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var isConnected = false
    private var reconnectTimer: Timer?
    private let decoder = JSONDecoder()
    
    init(host: String, port: String, state: TradingState) {
        self.host = host
        self.port = port
        self.state = state
        super.init()
    }
    
    func connect() {
        guard let url = URL(string: "ws://\(host):\(port)") else {
            print("[WS] Invalid URL: ws://\(host):\(port)")
            return
        }
        
        print("[WS] Connecting to \(url)...")
        session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        Task { @MainActor in
            state?.isConnected = false
        }
    }
    
    // MARK: - URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("[WS] Connected!")
        isConnected = true
        Task { @MainActor in
            state?.isConnected = true
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("[WS] Disconnected: \(closeCode)")
        isConnected = false
        Task { @MainActor in
            state?.isConnected = false
        }
        scheduleReconnect()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("[WS] Error: \(error.localizedDescription)")
            isConnected = false
            Task { @MainActor in
                state?.isConnected = false
            }
            scheduleReconnect()
        }
    }
    
    // MARK: - Message Handling
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                // Continue receiving
                self.receiveMessage()
                
            case .failure(let error):
                print("[WS] Receive error: \(error.localizedDescription)")
                self.isConnected = false
                Task { @MainActor in
                    self.state?.isConnected = false
                }
                self.scheduleReconnect()
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        // Decode type first
        guard let envelope = try? decoder.decode(ServerMessageEnvelope.self, from: data) else { return }
        
        Task { @MainActor [weak self] in
            guard let self = self, let state = self.state else { return }
            
            switch envelope.type {
            case "welcome":
                if let msg = try? self.decoder.decode(WelcomeMessage.self, from: data) {
                    state.serverVersion = msg.server_version ?? ""
                    state.eaConnected = msg.ea_connected ?? false
                    state.eaVersion = msg.ea_version ?? ""
                    state.eaSymbol = msg.ea_symbol ?? ""
                    state.serverUptime = msg.server_uptime_secs ?? 0
                    state.isConnected = true
                    
                    // Start Live Activity on connect
                    if state.liveActivityEnabled {
                        LiveActivityManager.shared.startActivity(state: state)
                    }
                }
                
            case "telemetry":
                if let msg = try? self.decoder.decode(TelemetryMessage.self, from: data) {
                    state.cpuUsage = msg.cpu ?? 0
                    state.ramMB = msg.ram_mb ?? 0
                    state.totalRamMB = msg.total_ram_mb ?? 0
                }
                
            case "pipeline_result":
                if let msg = try? self.decoder.decode(PipelineResultMessage.self, from: data) {
                    let symbol = msg.symbol ?? ""
                    let result = msg.result
                    
                    var ps = state.pipelineStatus[symbol] ?? PipelineSymbolState(id: symbol)
                    ps.status = "done"
                    ps.lastDecision = result?.decision ?? "HOLD"
                    ps.lastConfidence = result?.confidence ?? 0
                    ps.lastStrategy = result?.strategy_name ?? ""
                    ps.lastTimeframe = result?.timeframe ?? ""
                    ps.lastReasoning = result?.reasoning ?? ""
                    ps.buySignals = result?.server_scan?.buy_signals ?? 0
                    ps.sellSignals = result?.server_scan?.sell_signals ?? 0
                    ps.atrRatio = result?.server_scan?.atr_ratio ?? 1.0
                    ps.topSignals = result?.server_scan?.top_signals ?? []
                    ps.gemmaVerdict = result?.gemma_verdict ?? ""
                    ps.geminiVerdict = result?.gemini_verdict ?? ""
                    ps.updatedAt = Date()
                    state.pipelineStatus[symbol] = ps
                    
                    // Update last signal
                    if let decision = result?.decision, decision == "BUY" || decision == "SELL" {
                        state.lastSignal = decision
                        state.lastSignalSymbol = symbol
                        state.lastSignalConfidence = result?.confidence ?? 0
                        state.lastSignalStrategy = result?.strategy_name ?? ""
                        state.lastSignalTimeframe = result?.timeframe ?? ""
                    }
                    
                    // Update Live Activity
                    if state.liveActivityEnabled {
                        LiveActivityManager.shared.updateActivity(state: state)
                    }
                }
                
            case "agents_started":
                if let msg = try? self.decoder.decode(AgentsStatusMessage.self, from: data) {
                    let symbol = msg.symbol ?? ""
                    var ps = state.pipelineStatus[symbol] ?? PipelineSymbolState(id: symbol)
                    ps.status = "scanning"
                    state.pipelineStatus[symbol] = ps
                }
                
            case "agents_done":
                if let msg = try? self.decoder.decode(AgentsStatusMessage.self, from: data) {
                    let symbol = msg.symbol ?? ""
                    var ps = state.pipelineStatus[symbol] ?? PipelineSymbolState(id: symbol)
                    ps.status = "done"
                    state.pipelineStatus[symbol] = ps
                }
                
            case "agent_log":
                if let msg = try? self.decoder.decode(AgentLogMessage.self, from: data) {
                    let entry = AgentLogEntry(
                        symbol: msg.symbol ?? "",
                        agent: msg.agent ?? "",
                        status: msg.status ?? "",
                        message: Self.stripEmojis(msg.message ?? "")
                    )
                    state.addLog(entry)
                    
                    // Update pipeline status based on agent
                    let symbol = msg.symbol ?? ""
                    var ps = state.pipelineStatus[symbol] ?? PipelineSymbolState(id: symbol)
                    if msg.agent == "gemini_confirm" && msg.status == "running" {
                        ps.status = "ai_confirm"
                    }
                    state.pipelineStatus[symbol] = ps
                }
                
            case "ai_trade_proposal":
                if let msg = try? self.decoder.decode(AITradeProposal.self, from: data) {
                    state.lastSignal = msg.direction ?? "HOLD"
                    state.lastSignalSymbol = msg.symbol ?? ""
                    state.lastSignalConfidence = msg.confidence ?? 0
                    state.lastSignalStrategy = msg.strategy ?? ""
                    state.lastSignalTimeframe = msg.timeframe ?? ""
                    
                    if state.liveActivityEnabled {
                        LiveActivityManager.shared.updateActivity(state: state)
                    }
                }
                
            case "position_manage_result":
                if let msg = try? self.decoder.decode(PositionManageResultMessage.self, from: data) {
                    if let results = msg.results {
                        state.positions = results.map { action in
                            PositionInfo(
                                id: action.ticket ?? 0,
                                symbol: msg.symbol ?? "",
                                direction: action.hedge_direction ?? "—",
                                lotSize: action.hedge_lot ?? 0,
                                pnl: 0,
                                openPrice: 0,
                                currentPrice: 0,
                                action: action.action ?? "HOLD",
                                reasoning: action.reasoning ?? ""
                            )
                        }
                        state.openPositionCount = msg.position_count ?? results.count
                    }
                    
                    if state.liveActivityEnabled {
                        LiveActivityManager.shared.updateActivity(state: state)
                    }
                }
                
                
            case "history":
                if let msg = try? self.decoder.decode(HistoryMessage.self, from: data) {
                    let incomingCandles = msg.candles ?? []
                    
                    // If MT5 sends empty array, but we already have data, ignore it
                    if !incomingCandles.isEmpty || msg.source == "server_db" {
                        DispatchQueue.main.async {
                            self.state?.mt5Candles = incomingCandles
                            self.state?.isChartLoading = false
                        }
                    } else if incomingCandles.isEmpty {
                         // Only clear loading state but don't wipe out good data
                         DispatchQueue.main.async {
                             self.state?.isChartLoading = false
                         }
                    }
                }
                
            case "tracked_symbols":
                if let msg = try? self.decoder.decode(TrackedSymbolsMessage.self, from: data) {
                    if let symbols = msg.symbols, !symbols.isEmpty {
                        DispatchQueue.main.async {
                            self.state?.availableSymbols = symbols
                        }
                    }
                }
                
            case "gcs_config", "gcs_config_saved":
                if let msg = try? self.decoder.decode(GcsConfigMessage.self, from: data) {
                    DispatchQueue.main.async {
                        self.state?.gcsConfigured = msg.has_sa ?? false
                        self.state?.bucketName = msg.bucket_name ?? ""
                        if let history = msg.upload_history {
                            self.state?.uploadHistory = history
                        }
                    }
                }
                
            case "upload_video_status":
                if let msg = try? self.decoder.decode(UploadVideoStatusMessage.self, from: data) {
                    DispatchQueue.main.async {
                        if msg.status == "error" {
                            self.state?.videoUploadStatus = .error(msg.error ?? "Unknown error")
                        } else if msg.status == "started" {
                            self.state?.videoUploadStatus = .started
                        } else if msg.status == "done" {
                            self.state?.videoUploadStatus = .done(
                                fileName: msg.file_name ?? "Video",
                                cloudLink: msg.cloud_link ?? "",
                                fileId: msg.file_id ?? ""
                            )
                            // Refresh history
                            self.requestGcsConfig()
                        }
                    }
                }
                
            case "upload_video_progress":
                if let msg = try? self.decoder.decode(UploadVideoProgressMessage.self, from: data) {
                    DispatchQueue.main.async {
                        if msg.stage == "downloading" {
                            self.state?.videoUploadStatus = .downloading(progress: msg.progress ?? 0)
                        } else if msg.stage == "uploading" {
                            self.state?.videoUploadStatus = .uploading(progress: msg.progress ?? 50)
                        }
                    }
                }
                
            default:
                break
            }
        }
    }
    
    // MARK: - Reconnect
    
    private func scheduleReconnect() {
        guard reconnectTimer == nil else { return }
        print("[WS] Scheduling reconnect in 5s...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            self.reconnectTimer = nil
            print("[WS] Reconnecting...")
            self.connect()
        }
    }
    
    // MARK: - Helpers
    
    static func stripEmojis(_ text: String) -> String {
        return text.unicodeScalars.filter { scalar in
            // Keep ASCII and common Unicode but strip emoji ranges
            let v = scalar.value
            if v <= 0x007F { return true } // ASCII
            if v >= 0x0080 && v <= 0x07FF { return true } // Latin extended, Thai, etc.
            if v >= 0x0E00 && v <= 0x0E7F { return true } // Thai
            if v >= 0x2000 && v <= 0x206F { return true } // General punctuation
            if v >= 0x3000 && v <= 0x9FFF { return true } // CJK
            if v >= 0xFF00 && v <= 0xFFEF { return true } // Fullwidth
            return false
        }.map { String($0) }.joined()
    }
    
    func sendMessage(_ text: String) {
        webSocketTask?.send(.string(text)) { error in
            if let error = error {
                print("[WS] Send error: \(error.localizedDescription)")
            }
        }
    }
    
    func requestCandles(symbol: String = "XAUUSD", timeframe: String = "M5") {
        let cmd = [
            "action": "request_candles",
            "symbol": symbol,
            "timeframe": timeframe
        ]
        if let data = try? JSONSerialization.data(withJSONObject: cmd),
           let str = String(data: data, encoding: .utf8) {
            sendMessage(str)
        }
    }
    
    func requestTrackedSymbols() {
        let cmd = ["action": "get_tracked_symbols"]
        if let data = try? JSONSerialization.data(withJSONObject: cmd),
           let str = String(data: data, encoding: .utf8) {
            sendMessage(str)
        }
    }
    
    // MARK: - Drive Video Upload Methods
    
    func uploadVideoFromURL(url: String) {
        let cmd: [String: String] = [
            "action": "upload_video_from_url",
            "video_url": url
        ]
        if let data = try? JSONSerialization.data(withJSONObject: cmd),
           let str = String(data: data, encoding: .utf8) {
            sendMessage(str)
        }
    }
    
    func saveGcsConfig(serviceAccountJSON: String?, bucketName: String?) {
        var cmd: [String: String] = ["action": "set_gcs_config"]
        if let sa = serviceAccountJSON { cmd["gcs_service_account"] = sa }
        if let bkt = bucketName { cmd["bucket_name"] = bkt }
        
        if let data = try? JSONSerialization.data(withJSONObject: cmd),
           let str = String(data: data, encoding: .utf8) {
            sendMessage(str)
        }
    }
    
    func requestGcsConfig() {
        let cmd = ["action": "get_gcs_config"]
        if let data = try? JSONSerialization.data(withJSONObject: cmd),
           let str = String(data: data, encoding: .utf8) {
            sendMessage(str)
        }
    }
}
