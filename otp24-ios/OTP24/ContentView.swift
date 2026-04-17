import SwiftUI

struct ContentView: View {
    @EnvironmentObject var api: APIService
    
    var body: some View {
        ZStack {
            OTPGradients.background.ignoresSafeArea()
            
            if api.isLoggedIn {
                MainTabView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                LoginView()
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: api.isLoggedIn)
        .task {
            await api.autoLogin()
        }
    }
}
