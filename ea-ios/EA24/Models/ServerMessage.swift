import Foundation

// MARK: - Generic Server Message (decode "type" first)
struct ServerMessageEnvelope: Codable {
    let type: String
}

// MARK: - Welcome
struct WelcomeMessage: Codable {
    let type: String
    let message: String?
    let status: String?
    let server_version: String?
    let latest_ea_version: String?
    let ea_connected: Bool?
    let ea_version: String?
    let ea_symbol: String?
    let update_available: Bool?
    let server_uptime_secs: Int?
}

// MARK: - Telemetry
struct TelemetryMessage: Codable {
    let type: String
    let cpu: Double?
    let ram_mb: Int?
    let total_ram_mb: Int?
    let rx_kb: Double?
    let tx_kb: Double?
    let db_pool: Int?
}

// MARK: - Pipeline Result
struct PipelineResultMessage: Codable {
    let type: String
    let symbol: String?
    let result: PipelineResult?
}

struct PipelineResult: Codable {
    let decision: String?
    let confidence: Double?
    let lot_size: Double?
    let strategy_name: String?
    let timeframe: String?
    let reasoning: String?
    let gemma_verdict: String?
    let gemini_verdict: String?
    let server_scan: ServerScanResult?
}

struct ServerScanResult: Codable {
    let strategies_scanned: Int?
    let timeframes_scanned: Int?
    let total_signals: Int?
    let buy_signals: Int?
    let sell_signals: Int?
    let scan_time_ms: Int?
    let atr_ratio: Double?
    let top_signals: [TopSignal]?
}

struct TopSignal: Codable, Identifiable {
    var id: Int { rank ?? 0 }
    let rank: Int?
    let strategy_name: String?
    let timeframe: String?
    let direction: String?
    let score: Double?
    let base_confidence: Double?
    let reason: String?
}

// MARK: - Agent Log
struct AgentLogMessage: Codable {
    let type: String
    let symbol: String?
    let agent: String?
    let status: String?
    let message: String?
}

// MARK: - AI Trade Proposal
struct AITradeProposal: Codable {
    let type: String
    let symbol: String?
    let direction: String?
    let confidence: Double?
    let reasoning: String?
    let lot_size: Double?
    let strategy: String?
    let timeframe: String?
}

// MARK: - Agents Started/Done
struct AgentsStatusMessage: Codable {
    let type: String
    let symbol: String?
    let message: String?
}

// MARK: - Position Manage Result
struct PositionManageResultMessage: Codable {
    let type: String
    let symbol: String?
    let position_count: Int?
    let results: [PositionAction]?
}

struct PositionAction: Codable, Identifiable {
    var id: Int { ticket ?? 0 }
    let ticket: Int?
    let action: String?
    let reasoning: String?
    let recovery_score: Int?
    let hedge_direction: String?
    let hedge_lot: Double?
}

// MARK: - Global AI Data
struct GlobalAIDataMessage: Codable {
    let type: String
    let data: GlobalAIData?
}

struct GlobalAIData: Codable {
    let last_updated: Int?
}

// MARK: - MT5 History
struct HistoryMessage: Codable {
    let type: String
    let symbol: String?
    let timeframe: String?
    let candles: [CandleData]?
    let source: String?
}

struct CandleData: Codable, Identifiable {
    var id: Int64 { time ?? 0 }
    let time: Int64?
    let open: Double?
    let high: Double?
    let low: Double?
    let close: Double?
}

// MARK: - Tracked Symbols
struct TrackedSymbolsMessage: Codable {
    let type: String
    let symbols: [String]?
}

// MARK: - GCS Messages
struct GcsConfigMessage: Codable {
    let type: String
    let has_sa: Bool?
    let bucket_name: String?
    let upload_history: [VideoUploadRecord]?
}

struct GcsConfigSavedMessage: Codable {
    let type: String
    let has_sa: Bool?
    let bucket_name: String?
}

struct UploadVideoStatusMessage: Codable {
    let type: String
    let job_id: String?
    let status: String?
    let error: String?
    let url: String?
    let file_name: String?
    let file_id: String?
    let cloud_link: String?
    let size_bytes: Int?
}

struct UploadVideoProgressMessage: Codable {
    let type: String
    let job_id: String?
    let stage: String?
    let progress: Int?
    let downloaded_bytes: Int?
    let total_bytes: Int?
}

