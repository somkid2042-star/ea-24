import SwiftUI

struct OTP24ServerListView: View {
    @EnvironmentObject var otpState: OTP24State
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            FA.bg.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // App header
                    if let app = otpState.selectedApp {
                        HStack(spacing: 14) {
                            AsyncImage(url: URL(string: app.icon_url)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFit()
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                default:
                                    Image(systemName: app.iconSystemName)
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(FA.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(FA.textDark)
                                
                                Text("\(otpState.nodes.count) servers")
                                    .font(.system(size: 13))
                                    .foregroundColor(FA.textMedium)
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .faCard(16)
                    }
                    
                    // Server list
                    ForEach(otpState.nodes) { node in
                        serverCard(node)
                    }
                    
                    if otpState.nodes.isEmpty && !otpState.isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "server.rack")
                                .font(.system(size: 40))
                                .foregroundColor(FA.textLight)
                            Text("No servers found")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(FA.textMedium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            
            if otpState.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                            Text("Extracting cookies...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    )
            }
        }
        .navigationTitle(otpState.selectedApp?.name ?? "Servers")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Server Card
    
    private func serverCard(_ node: OTP24Node) -> some View {
        Button(action: {
            if node.can_access && node.is_working {
                Task { await otpState.getCookieAndOpen(nodeId: node.id) }
            }
        }) {
            HStack(spacing: 14) {
                // Status indicator
                Circle()
                    .fill(statusColor(node))
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.server_name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(FA.textDark)
                    
                    Text(statusText(node))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(statusColor(node))
                }
                
                Spacer()
                
                if !node.can_access {
                    // Lock badge
                    Text(node.lock_app ?? "Locked")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(FA.exchange)
                        .clipShape(Capsule())
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(FA.textLight)
                } else if node.is_working {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(FA.textLight)
                }
            }
            .padding(16)
            .faCard(14)
        }
        .disabled(!node.can_access || !node.is_working)
        .opacity(!node.can_access || !node.is_working ? 0.6 : 1)
    }
    
    private func statusColor(_ node: OTP24Node) -> Color {
        if !node.can_access { return FA.exchange }
        return node.is_working ? FA.incomeGreen : FA.expenseRed
    }
    
    private func statusText(_ node: OTP24Node) -> String {
        if !node.can_access { return node.lock_msg ?? "Upgrade required" }
        return node.is_working ? "ONLINE" : "MAINTENANCE"
    }
}
