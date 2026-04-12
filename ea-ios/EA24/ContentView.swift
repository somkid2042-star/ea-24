import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tradingState: TradingState
    @State private var selectedTab = 0
    @State private var showSideMenu = false
    
    init() {
        // Navigation bar styling
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(TeofinColors.backgroundTop)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(TeofinColors.title)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(TeofinColors.title)]
        navAppearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView(showSideMenu: $showSideMenu)
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)
                
                PositionsView()
                    .tag(1)
                    .toolbar(.hidden, for: .tabBar)
                
                PipelineView()
                    .tag(2)
                    .toolbar(.hidden, for: .tabBar)
                
                VideoUploadView()
                    .tag(3)
                    .toolbar(.hidden, for: .tabBar)
                
                SettingsView()
                    .tag(4)
                    .toolbar(.hidden, for: .tabBar)
            }
            .padding(.bottom, 60) // Add padding so content is not behind the tab bar
            
            if !showSideMenu {
                CustomTabBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

#Preview {
    ContentView()
        .environmentObject(TradingState())
}
