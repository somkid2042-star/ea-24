import SwiftUI

struct OTP24HomeView: View {
    @StateObject private var otpState = OTP24State()
    
    var body: some View {
        NavigationStack {
            ZStack {
                FA.bg.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // ══════════════════════════════════════
                        //  PURPLE HEADER
                        // ══════════════════════════════════════
                        ZStack(alignment: .top) {
                            LinearGradient(
                                colors: [FA.primaryDark, FA.primary, FA.primaryLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 340)
                            .padding(.top, -100)
                            .ignoresSafeArea(edges: .top)
                            
                            VStack(spacing: 0) {
                                // Top bar
                                HStack {
                                    Image(systemName: "key.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("OTP24")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if otpState.isLoggedIn {
                                        // Package badge
                                        Text(otpState.packageType.uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(packageColor.opacity(0.6))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                
                                // License Key Card
                                VStack(alignment: .leading, spacing: 0) {
                                    if otpState.isLoggedIn {
                                        // Key info
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("License Key")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(FA.textMedium)
                                                
                                                Text(otpState.licenseKey)
                                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                                    .foregroundColor(FA.textDark)
                                            }
                                            
                                            Spacer()
                                            
                                            // Refresh button
                                            Button(action: { Task { await otpState.login() } }) {
                                                Image(systemName: "arrow.clockwise")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(FA.primary)
                                                    .frame(width: 44, height: 44)
                                                    .background(FA.primary.opacity(0.12))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 20)
                                        
                                        // Quick actions
                                        HStack(spacing: 0) {
                                            quickAction(icon: "plus.circle", label: "New Key", color: FA.cards) {
                                                Task { await otpState.createNewKey() }
                                            }
                                            quickAction(icon: "arrow.clockwise", label: "Refresh", color: FA.send) {
                                                Task { await otpState.login() }
                                            }
                                            quickAction(icon: "trash", label: "Logout", color: FA.withdraw) {
                                                otpState.logout()
                                            }
                                            quickAction(icon: "square.and.arrow.up", label: "Share", color: FA.exchange) {}
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.top, 16)
                                        .padding(.bottom, 20)
                                        
                                    } else {
                                        // Not logged in
                                        VStack(spacing: 16) {
                                            Image(systemName: "key.fill")
                                                .font(.system(size: 36))
                                                .foregroundColor(FA.primary)
                                            
                                            Text("OTP24 Premium Access")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(FA.textDark)
                                            
                                            Text("เข้าถึง Netflix, YouTube, ChatGPT\nและอีก 80+ แอประดับ Premium")
                                                .font(.system(size: 13))
                                                .foregroundColor(FA.textMedium)
                                                .multilineTextAlignment(.center)
                                            
                                            Button(action: { Task { await otpState.login() } }) {
                                                HStack {
                                                    Image(systemName: "bolt.fill")
                                                    Text("เริ่มต้นใช้งาน")
                                                }
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                                .background(
                                                    LinearGradient(colors: [FA.primary, FA.primaryDark], startPoint: .leading, endPoint: .trailing)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            }
                                        }
                                        .padding(24)
                                    }
                                }
                                .background(FA.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            }
                        }
                        
                        if otpState.isLoggedIn {
                            // ══════════════════════════════════════
                            //  STATS (Quota, Expiry, Package)
                            // ══════════════════════════════════════
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                statCard(title: "Quota", value: otpState.quotaText, color: FA.primary)
                                statCard(title: "Expires", value: "\(otpState.daysRemaining)d", color: otpState.daysRemaining <= 1 ? FA.expenseRed : FA.incomeGreen)
                                statCard(title: "Apps", value: "\(otpState.unlockedApps.count)", color: FA.exchange)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // ══════════════════════════════════════
                            //  APPS GRID
                            // ══════════════════════════════════════
                            HStack {
                                Text("Available Apps")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(FA.textDark)
                                
                                Spacer()
                                
                                Text("\(otpState.unlockedApps.count) / \(otpState.apps.count)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(FA.viewAll)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            
                            // Unlocked apps
                            OTP24AppGridView(
                                apps: otpState.unlockedApps,
                                onSelect: { app in
                                    Task { await otpState.loadNodes(for: app) }
                                    otpState.showServerList = true
                                }
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            
                            // Locked apps header
                            if !otpState.lockedApps.isEmpty {
                                HStack {
                                    Text("Locked Apps")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(FA.textDark)
                                    
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(FA.textLight)
                                    
                                    Spacer()
                                    
                                    Text("\(otpState.lockedApps.count)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(FA.textLight)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                                
                                OTP24AppGridView(
                                    apps: otpState.lockedApps,
                                    onSelect: { _ in }
                                )
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                            }
                        }
                        
                        Spacer(minLength: 120)
                    }
                }
                
                // Loading overlay
                if otpState.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                        )
                }
                
                // Toast
                if let toast = otpState.toastMessage {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(FA.incomeGreen.cornerRadius(12))
                            .padding(.bottom, 100)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            otpState.toastMessage = nil
                        }
                    }
                }
                
                // Error toast
                if let error = otpState.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(FA.expenseRed.cornerRadius(12))
                            .padding(.bottom, 100)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            otpState.errorMessage = nil
                        }
                    }
                }
            }
            .task {
                // ✅ Auto-login เมื่อเปิด tab — ไม่ต้องกดปุ่ม
                await otpState.autoLoginIfNeeded()
            }
            .navigationDestination(isPresented: $otpState.showServerList) {
                OTP24ServerListView()
                    .environmentObject(otpState)
            }
            .fullScreenCover(isPresented: $otpState.showWebBrowser) {
                OTP24WebBrowserView(
                    url: otpState.browserURL,
                    cookies: otpState.browserCookies
                )
            }
        }
    }
    
    // MARK: - Quick Action
    
    private func quickAction(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(Circle())
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FA.textMedium)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Stat Card
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(FA.textMedium)
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .faCard(14)
    }
    
    private var packageColor: Color {
        switch otpState.packageType.lowercased() {
        case "exclusive": return FA.withdraw
        case "standard": return FA.exchange
        case "basic": return FA.primary
        default: return FA.cards
        }
    }
}

#Preview {
    OTP24HomeView()
}
