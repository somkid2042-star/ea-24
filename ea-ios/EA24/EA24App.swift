import SwiftUI

@main
struct EA24App: App {
    @StateObject private var tradingState = TradingState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tradingState)
        }
    }
}
