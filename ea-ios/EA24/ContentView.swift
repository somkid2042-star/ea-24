import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tradingState: TradingState
    var body: some View {
        VideoUploadView()
    }
}

#Preview {
    ContentView()
        .environmentObject(TradingState())
}
