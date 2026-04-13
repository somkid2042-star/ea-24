import SwiftUI

struct SideMenuView: View {
    @EnvironmentObject var state: AppState
    @Binding var isOpen: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            if isOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isOpen = false
                        }
                    }
            }
            
            HStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // ═══════════════════════════════════════
                        //  PROFILE HEADER (avatar + name + X)
                        // ═══════════════════════════════════════
                        HStack(spacing: 14) {
                            Image("ProfileAvatar")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(FA.primary.opacity(0.3), lineWidth: 2))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cashflow User")
                                    .font(.camingo(17, weight: .bold))
                                    .foregroundColor(FA.textDark)
                                Text("EA-24")
                                    .font(.camingo(13))
                                    .foregroundColor(FA.textLight)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isOpen = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(FA.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 16)
                        
                        // ═══════════════════════════════════════
                        //  BALANCE CARD (purple gradient)
                        // ═══════════════════════════════════════
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Balance")
                                .font(.camingo(13))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                            
                            Text("$ \((state.summary?.balance ?? 2562.50).money)")
                                .font(.camingo(34, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            // ═══════════════════════════════════════
                            //  QUICK ACTIONS (4 circles) INSIDE CARD
                            // ═══════════════════════════════════════
                            HStack(spacing: 0) {
                                sideQuickAction(icon: "plus", label: "Deposit")
                                sideQuickAction(icon: "arrow.down", label: "Withdraw")
                                sideQuickAction(icon: "arrow.right", label: "Send")
                                sideQuickAction(icon: "creditcard", label: "My Cards")
                            }
                            .padding(.top, 28)
                            .padding(.bottom, 24)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                colors: [FA.primaryLight, FA.primary, FA.primaryDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        // Removed padding here so it runs edge to edge
                        
                        // ═══════════════════════════════════════
                        //  MENU SECTION
                        // ═══════════════════════════════════════
                        Text("Menu")
                            .font(.camingo(14))
                            .foregroundColor(FA.textLight)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 8)
                        
                        sideMenuItem(
                            icon: "chart.pie",
                            label: "Overview",
                            tab: .dashboard,
                            badge: state.transactions.count
                        )
                        sideMenuItem(icon: "doc.text", label: "Pages", tab: .transactions)
                        sideMenuItem(icon: "square.grid.2x2", label: "Components", tab: .analytics)
                        sideMenuItem(icon: "creditcard", label: "My Cards", tab: .otp24)
                        
                        // ═══════════════════════════════════════
                        //  OTHERS SECTION
                        // ═══════════════════════════════════════
                        Text("Others")
                            .font(.camingo(14))
                            .foregroundColor(FA.textLight)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 8)
                        
                        sideMenuItem(icon: "gearshape", label: "Settings", tab: .settings)
                        sideMenuItem(icon: "bubble.left", label: "Support", tab: nil)
                        
                        // Log out
                        Button(action: {}) {
                            HStack(spacing: 16) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(FA.primary)
                                    .clipShape(Circle())
                                
                                Text("Log out")
                                    .font(.camingo(16, weight: .medium))
                                    .foregroundColor(FA.textDark)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(FA.textLight)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                        
                        Spacer().frame(height: 60)
                    }
                }
                .frame(width: UIScreen.main.bounds.width * 0.82)
                .background(FA.surface)
                
                Spacer()
            }
            .offset(x: isOpen ? 0 : -(UIScreen.main.bounds.width))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isOpen)
    }
    
    // MARK: - Quick Action Circle
    private func sideQuickAction(icon: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.15))
                .clipShape(Circle())
            
            Text(label)
                .font(.camingo(11))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Menu Item Row
    private func sideMenuItem(icon: String, label: String, tab: TabItem?, badge: Int = 0) -> some View {
        Button(action: {
            if let tab = tab {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    state.selectedTab = tab
                    isOpen = false
                }
            }
        }) {
            HStack(spacing: 16) {
                // Circle icon (solid purple)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(FA.primary)
                    .clipShape(Circle())
                
                Text(label)
                    .font(.camingo(16, weight: .medium))
                    .foregroundColor(FA.textDark)
                
                Spacer()
                
                if badge > 0 {
                    Text("\(badge)")
                        .font(.camingo(12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(FA.primary)
                        .clipShape(Circle())
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(FA.textLight)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    SideMenuView(isOpen: .constant(true))
        .environmentObject(AppState())
}
