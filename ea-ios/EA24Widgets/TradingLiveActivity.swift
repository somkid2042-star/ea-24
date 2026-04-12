import SwiftUI
import WidgetKit
import ActivityKit

/// Dynamic Island Live Activity Widget
struct TradingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TradingActivityAttributes.self) { context in
            // ═══════════════════════════════════════
            //  LOCK SCREEN / Banner — Live Activity
            // ═══════════════════════════════════════
            lockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.85))
                .activitySystemActionForegroundColor(.cyan)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // ═══════════════════════════════════════
                //  EXPANDED View (long press)
                // ═══════════════════════════════════════
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EA-24")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(context.state.serverOnline ? .green : .red)
                                .frame(width: 6, height: 6)
                            Text(context.state.serverOnline ? "Online" : "Offline")
                                .font(.caption2)
                                .foregroundStyle(context.state.serverOnline ? .green : .red)
                        }
                        
                        if context.state.eaConnected {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.cyan)
                                    .frame(width: 6, height: 6)
                                Text("MT5")
                                    .font(.caption2)
                                    .foregroundStyle(.cyan)
                            }
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("P&L")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Text(formatPnL(context.state.totalPnL))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(pnlColor(context.state.totalPnL))
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 6) {
                        if context.state.lastSignal != "HOLD" && !context.state.lastSignalSymbol.isEmpty {
                            HStack(spacing: 6) {
                                Text(context.state.lastSignal)
                                    .font(.caption)
                                    .fontWeight(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(signalColor(context.state.lastSignal))
                                    .clipShape(Capsule())
                                
                                Text(context.state.lastSignalSymbol)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                
                                Text("\(Int(context.state.confidence))%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Monitoring...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label("\(context.state.openPositions)", systemImage: "list.bullet")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        pipelineStatusView(context.state.pipelineStatus)
                        
                        Spacer()
                        
                        if context.state.equity > 0 {
                            Text(String(format: "$%.0f", context.state.equity))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
            } compactLeading: {
                // ═══════════════════════════════════════
                //  COMPACT — Leading (small pill left)
                // ═══════════════════════════════════════
                HStack(spacing: 3) {
                    Circle()
                        .fill(context.state.serverOnline ? .green : .red)
                        .frame(width: 6, height: 6)
                    
                    if context.state.lastSignal != "HOLD" {
                        Text(context.state.lastSignal)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(signalColor(context.state.lastSignal))
                    } else {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption2)
                            .foregroundStyle(.cyan)
                    }
                }
                
            } compactTrailing: {
                // ═══════════════════════════════════════
                //  COMPACT — Trailing (small pill right)
                // ═══════════════════════════════════════
                Text(formatPnLShort(context.state.totalPnL))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(pnlColor(context.state.totalPnL))
                
            } minimal: {
                // ═══════════════════════════════════════
                //  MINIMAL — Single circle
                // ═══════════════════════════════════════
                Image(systemName: context.state.totalPnL >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(pnlColor(context.state.totalPnL))
            }
        }
    }
    
    // MARK: - Lock Screen View
    
    @ViewBuilder
    func lockScreenView(context: ActivityViewContext<TradingActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            // Left: Status
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    Text("EA-24 Trading")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(context.state.serverOnline ? .green : .red)
                        .frame(width: 6, height: 6)
                    Text(context.state.serverOnline ? "Server Online" : "Server Offline")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if context.state.eaConnected {
                        Circle()
                            .fill(.cyan)
                            .frame(width: 6, height: 6)
                        Text("MT5")
                            .font(.caption2)
                            .foregroundStyle(.cyan)
                    }
                }
                
                if context.state.lastSignal != "HOLD" {
                    HStack(spacing: 4) {
                        Text(context.state.lastSignal)
                            .font(.caption2)
                            .fontWeight(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(signalColor(context.state.lastSignal))
                            .clipShape(Capsule())
                        Text(context.state.lastSignalSymbol)
                            .font(.caption2)
                            .fontWeight(.medium)
                        Text("\(Int(context.state.confidence))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Right: P&L
            VStack(alignment: .trailing, spacing: 4) {
                Text("P&L")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Text(formatPnL(context.state.totalPnL))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(pnlColor(context.state.totalPnL))
                
                HStack(spacing: 8) {
                    Label("\(context.state.openPositions) pos", systemImage: "list.bullet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
    }
    
    // MARK: - Helpers
    
    func formatPnL(_ value: Double) -> String {
        let prefix = value >= 0 ? "+$" : "-$"
        return String(format: "%@%.2f", prefix, abs(value))
    }
    
    func formatPnLShort(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : "-"
        let absVal = abs(value)
        if absVal >= 1000 {
            return String(format: "%@%.1fk", prefix, absVal/1000)
        }
        return String(format: "%@$%.0f", prefix, absVal)
    }
    
    func pnlColor(_ value: Double) -> Color {
        if value > 0 { return .green }
        if value < 0 { return .red }
        return .gray
    }
    
    func signalColor(_ signal: String) -> Color {
        switch signal {
        case "BUY": return .green
        case "SELL": return .red
        default: return .gray
        }
    }
    
    @ViewBuilder
    func pipelineStatusView(_ status: String) -> some View {
        HStack(spacing: 4) {
            switch status {
            case "scanning":
                ProgressView()
                    .scaleEffect(0.5)
                Text("Scanning")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            case "ai_confirm":
                ProgressView()
                    .scaleEffect(0.5)
                Text("AI Confirm")
                    .font(.caption2)
                    .foregroundStyle(.purple)
            default:
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Text("Ready")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
