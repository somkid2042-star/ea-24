import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @State private var darkMode = false
    @State private var paymentAlert = false
    @State private var privateProfile = false
    @State private var twoStepVerification = true
    
    var body: some View {
        VStack(spacing: 0) {
            // ── Header (matches Finapp app-settings.html) ──
            ZStack {
                FA.primary
                    .padding(.top, -100)
                    .ignoresSafeArea(edges: .top)
                
                HStack {
                    Spacer()
                    Text("Settings")
                        .font(.camingo(20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .overlay(alignment: .trailing) {
                    // Notification bell (matching Finapp header)
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white)
                        
                        Text("4")
                            .font(.camingo(9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(FA.notifBadge)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 8)
            }
            .frame(height: 56)
            
            ScrollView {
                VStack(spacing: 0) {
                    // ══════════════════════════════════════
                    //  AVATAR SECTION (Finapp: avatar-section)
                    // ══════════════════════════════════════
                    VStack(spacing: 0) {
                        ZStack(alignment: .bottomTrailing) {
                            Image("ProfileAvatar")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(FA.border, lineWidth: 2))
                            
                            // Camera icon overlay (matches Finapp)
                            Image(systemName: "camera")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(FA.primary)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(FA.surface, lineWidth: 2))
                                .offset(x: 4, y: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    
                    // ══════════════════════════════════════
                    //  THEME SECTION
                    // ══════════════════════════════════════
                    sectionTitle("Theme")
                    
                    VStack(spacing: 0) {
                        settingsToggleRow(title: "Dark Mode", isOn: $darkMode)
                    }
                    .faCard(12)
                    .padding(.horizontal, 20)
                    
                    // ══════════════════════════════════════
                    //  NOTIFICATIONS SECTION
                    // ══════════════════════════════════════
                    sectionTitle("Notifications")
                    
                    VStack(spacing: 0) {
                        settingsToggleRow(
                            title: "Payment Alert",
                            subtitle: "Send notification when new payment received",
                            isOn: $paymentAlert
                        )
                        Divider().padding(.leading, 16)
                        settingsNavRow(title: "Notification Sound", value: "Beep")
                    }
                    .faCard(12)
                    .padding(.horizontal, 20)
                    
                    // ══════════════════════════════════════
                    //  PROFILE SETTINGS SECTION
                    // ══════════════════════════════════════
                    sectionTitle("Profile Settings")
                    
                    VStack(spacing: 0) {
                        settingsNavRow(title: "Change Username")
                        Divider().padding(.leading, 16)
                        settingsNavRow(title: "Update E-mail")
                        Divider().padding(.leading, 16)
                        settingsNavRow(title: "Address", value: "Edit")
                        Divider().padding(.leading, 16)
                        settingsToggleRow(title: "Private Profile", isOn: $privateProfile)
                    }
                    .faCard(12)
                    .padding(.horizontal, 20)
                    
                    // ══════════════════════════════════════
                    //  SECURITY SECTION
                    // ══════════════════════════════════════
                    sectionTitle("Security")
                    
                    VStack(spacing: 0) {
                        settingsNavRow(title: "Update Password")
                        Divider().padding(.leading, 16)
                        settingsToggleRow(title: "2 Step Verification", isOn: $twoStepVerification)
                        Divider().padding(.leading, 16)
                        settingsNavRow(title: "Log out all devices")
                    }
                    .faCard(12)
                    .padding(.horizontal, 20)
                    
                    // ══════════════════════════════════════
                    //  SERVER CONFIG (app-specific, kept)
                    // ══════════════════════════════════════
                    sectionTitle("Server")
                    
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: "server.rack")
                                .font(.camingo(16))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(FA.send)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Server")
                                    .font(.camingo(15, weight: .medium))
                                    .foregroundColor(FA.textDark)
                                Text("\(state.serverHost):\(state.httpPort)")
                                    .font(.camingo(12))
                                    .foregroundColor(FA.textLight)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .faCard(12)
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 120)
                }
            }
            .background(FA.bg)
        }
        .background(FA.primary.ignoresSafeArea(edges: .top))
    }
    
    // MARK: - Section Title (Finapp listview-title style)
    
    private func sectionTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.camingo(13, weight: .medium))
                .foregroundColor(FA.textLight)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
    
    // MARK: - Navigation Row (Finapp list item with chevron)
    
    private func settingsNavRow(title: String, value: String? = nil) -> some View {
        Button(action: {}) {
            HStack {
                Text(title)
                    .font(.camingo(15, weight: .medium))
                    .foregroundColor(FA.textDark)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.camingo(14, weight: .medium))
                        .foregroundColor(FA.primary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FA.textLight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
    
    // MARK: - Toggle Row (Finapp switch style)
    
    private func settingsToggleRow(title: String, subtitle: String? = nil, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.camingo(15, weight: .medium))
                    .foregroundColor(FA.textDark)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.camingo(12))
                        .foregroundColor(FA.textLight)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(FA.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    SettingsView().environmentObject(AppState())
}
