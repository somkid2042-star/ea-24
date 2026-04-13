import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var showSideMenu = false
    
    var body: some View {
        ZStack {
            ZStack(alignment: .bottom) {
                FA.bg.ignoresSafeArea()
                
                Group {
                    switch state.selectedTab {
                    case .dashboard:
                        DashboardView(showSideMenu: $showSideMenu)
                    case .transactions:
                        TransactionListView()
                    case .analytics:
                        AnalyticsView()
                    case .otp24:
                        OTP24HomeView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Finapp Tab Bar
                FinappTabBar()
            }
            
            SideMenuView(isOpen: $showSideMenu)
        }
        .task { await state.loadAll() }
        .sheet(isPresented: $state.showAddSheet) {
            AddTransactionView()
                .environmentObject(state)
        }
    }
}

// MARK: - Finapp Tab Bar (with labels + active purple color)

struct FinappTabBar: View {
    @EnvironmentObject var state: AppState
    
    private let tabs: [(TabItem, String, String)] = [
        (.dashboard, "chart.pie", "Overview"),
        (.transactions, "doc.text", "Pages"),
        (.analytics, "square.grid.2x2", "Components"),
        (.otp24, "square.stack.3d.up", "MyApp"),
        (.settings, "gearshape", "Settings"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(tabs, id: \.0) { tab, icon, label in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            state.selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: icon)
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(
                                    state.selectedTab == tab ? FA.tabActive : FA.tabInactive
                                )
                            
                            Text(label)
                                .font(.camingo(10, weight: .medium))
                                .foregroundColor(
                                    state.selectedTab == tab ? FA.tabActive : FA.tabInactive
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                }
            }
            
            // Spacer pushes to bottom safe area
            Spacer().frame(height: 0)
        }
        .padding(.bottom, 0)
        .background(
            FA.surface
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
