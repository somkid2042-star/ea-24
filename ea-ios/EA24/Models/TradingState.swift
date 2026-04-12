import Foundation
import SwiftUI
import Combine

/// Observable trading state shared across all views
@MainActor
class TradingState: ObservableObject {
    // MARK: - Connection
    @Published var isConnected = false
    @Published var serverVersion = ""
    @Published var eaConnected = false
    @Published var eaVersion = ""
    @Published var eaSymbol = ""
    @Published var serverUptime: Int = 0
    
    // MARK: - Account
    @Published var balance: Double = 0.0
    
    @Published var equityHistory: [ChartDataPoint] = []
    @Published var equity: Double = 0.0 {
        didSet {
            // Only add if it changed or periodically 
            let point = ChartDataPoint(value: equity)
            equityHistory.append(point)
            if equityHistory.count > 50 {
                equityHistory.removeFirst()
            }
        }
    }
    
    @Published var totalPnL: Double = 0.0
    @Published var openPositionCount: Int = 0
    
    // MARK: - Chart Data
    @Published var mt5Candles: [CandleData] = []
    @Published var isChartLoading: Bool = true
    @Published var availableSymbols: [String] = ["XAUUSD"] // Default fallback
    @Published var selectedSymbol: String = "XAUUSD"
    @Published var selectedTimeframe: String = "M5"
    
    // MARK: - Telemetry
    @Published var cpuUsage: Double = 0.0
    @Published var ramMB: Int = 0
    @Published var totalRamMB: Int = 0
    
    // MARK: - Pipeline Status (per symbol)
    @Published var pipelineStatus: [String: PipelineSymbolState] = [:]
    
    // MARK: - Agent Logs
    @Published var agentLogs: [AgentLogEntry] = []
    
    // MARK: - Positions
    @Published var positions: [PositionInfo] = []
    
    // MARK: - Last Signal
    @Published var lastSignal: String = "HOLD"
    @Published var lastSignalSymbol: String = ""
    @Published var lastSignalConfidence: Double = 0
    @Published var lastSignalStrategy: String = ""
    @Published var lastSignalTimeframe: String = ""
    
    // MARK: - Settings
    @AppStorage("serverHost") var serverHost: String = "35.187.147.242"
    @AppStorage("serverPort") var serverPort: String = "8080"
    @AppStorage("liveActivityEnabled") var liveActivityEnabled: Bool = true
    
    // MARK: - Video Upload / Drive
    @Published var videoUploadStatus: VideoUploadStatus = .idle
    @Published var driveConfigured: Bool = false
    @Published var driveFolderID: String = ""
    @Published var uploadHistory: [VideoUploadRecord] = []
    
    // MARK: - WebSocket
    private var webSocketService: WebSocketService?
    
    init() {
        connect()
    }
    
    func connect() {
        webSocketService?.disconnect()
        webSocketService = WebSocketService(host: serverHost, port: serverPort, state: self)
        webSocketService?.connect()
    }
    
    func disconnect() {
        webSocketService?.disconnect()
    }
    
    func requestCandles(symbol: String? = nil, timeframe: String? = nil, silent: Bool = false) {
        let sym = symbol ?? selectedSymbol
        let tf = timeframe ?? selectedTimeframe
        
        // Don't request if socket is not properly initialized
        guard webSocketService != nil else { return }
        
        if !silent {
            isChartLoading = true
        }
        webSocketService?.requestCandles(symbol: sym, timeframe: tf)
    }
    
    func requestTrackedSymbols() {
        webSocketService?.requestTrackedSymbols()
    }
    
    var serverURL: String {
        "ws://\(serverHost):\(serverPort)"
    }
    
    func addLog(_ entry: AgentLogEntry) {
        agentLogs.insert(entry, at: 0)
        if agentLogs.count > 100 {
            agentLogs = Array(agentLogs.prefix(100))
        }
    }
    
    // MARK: - Drive Upload Methods
    
    func uploadVideoFromURL(_ url: String) {
        videoUploadStatus = .started
        webSocketService?.uploadVideoFromURL(url: url)
    }
    
    func saveDriveConfig(serviceAccountJSON: String?, folderID: String?) {
        webSocketService?.saveDriveConfig(serviceAccountJSON: serviceAccountJSON, folderID: folderID)
    }
    
    func requestDriveConfig() {
        webSocketService?.requestDriveConfig()
    }

// MARK: - Supporting Types

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date = Date()
    let value: Double
}

struct PipelineSymbolState: Identifiable {
    let id: String // symbol
    var status: String = "idle" // idle, scanning, ai_confirm, done
    var lastDecision: String = "HOLD"
    var lastConfidence: Double = 0
    var lastStrategy: String = ""
    var lastTimeframe: String = ""
    var lastReasoning: String = ""
    var buySignals: Int = 0
    var sellSignals: Int = 0
    var atrRatio: Double = 1.0
    var topSignals: [TopSignal] = []
    var gemmaVerdict: String = ""
    var geminiVerdict: String = ""
    var updatedAt: Date = Date()
}

struct AgentLogEntry: Identifiable {
    let id = UUID()
    let symbol: String
    let agent: String
    let status: String
    let message: String
    let timestamp: Date = Date()
}

struct PositionInfo: Identifiable {
    let id: Int // ticket
    let symbol: String
    let direction: String
    let lotSize: Double
    let pnl: Double
    let openPrice: Double
    let currentPrice: Double
    let action: String // from position manager
    let reasoning: String
}
