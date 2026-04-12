import ActivityKit
import Foundation

/// Attributes for Trading Live Activity (Dynamic Island)
struct TradingActivityAttributes: ActivityAttributes {
    
    /// Dynamic content state — updated in real-time
    struct ContentState: Codable, Hashable {
        var totalPnL: Double
        var openPositions: Int
        var lastSignal: String       // "BUY", "SELL", "HOLD"
        var lastSignalSymbol: String // "XAUUSD"
        var confidence: Double       // 0-100
        var pipelineStatus: String   // "idle", "scanning", "ai_confirm", "done"
        var equity: Double
        var balance: Double
        var serverOnline: Bool
        var eaConnected: Bool
    }
    
    /// Static attributes — set when activity starts
    var serverIP: String
    var startTime: Date
}
