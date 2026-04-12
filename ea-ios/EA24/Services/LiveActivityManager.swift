import Foundation
import ActivityKit

/// Manages Live Activities for Dynamic Island
@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<TradingActivityAttributes>?
    
    private init() {}
    
    func startActivity(state: TradingState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivity] Activities not enabled")
            return
        }
        
        // End existing activity first
        endActivity()
        
        let attributes = TradingActivityAttributes(
            serverIP: state.serverHost,
            startTime: Date()
        )
        
        let contentState = TradingActivityAttributes.ContentState(
            totalPnL: state.totalPnL,
            openPositions: state.openPositionCount,
            lastSignal: state.lastSignal,
            lastSignalSymbol: state.lastSignalSymbol,
            confidence: state.lastSignalConfidence,
            pipelineStatus: "connected",
            equity: state.equity,
            balance: state.balance,
            serverOnline: state.isConnected,
            eaConnected: state.eaConnected
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("[LiveActivity] Started: \(activity.id)")
        } catch {
            print("[LiveActivity] Failed to start: \(error)")
        }
    }
    
    func updateActivity(state: TradingState) {
        guard let activity = currentActivity else { return }
        
        let contentState = TradingActivityAttributes.ContentState(
            totalPnL: state.totalPnL,
            openPositions: state.openPositionCount,
            lastSignal: state.lastSignal,
            lastSignalSymbol: state.lastSignalSymbol,
            confidence: state.lastSignalConfidence,
            pipelineStatus: determinePipelineStatus(state),
            equity: state.equity,
            balance: state.balance,
            serverOnline: state.isConnected,
            eaConnected: state.eaConnected
        )
        
        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }
    
    func endActivity() {
        guard let activity = currentActivity else { return }
        
        let finalState = TradingActivityAttributes.ContentState(
            totalPnL: 0,
            openPositions: 0,
            lastSignal: "OFFLINE",
            lastSignalSymbol: "",
            confidence: 0,
            pipelineStatus: "offline",
            equity: 0,
            balance: 0,
            serverOnline: false,
            eaConnected: false
        )
        
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            self.currentActivity = nil
        }
    }
    
    private func determinePipelineStatus(_ state: TradingState) -> String {
        for (_, ps) in state.pipelineStatus {
            if ps.status == "scanning" { return "scanning" }
            if ps.status == "ai_confirm" { return "ai_confirm" }
        }
        return "idle"
    }
}
