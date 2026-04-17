import SwiftUI

struct ServerListView: View {
    @EnvironmentObject var api: APIService
    let app: OTPApp
    
    @State private var nodes: [ServerNode] = []
    @State private var isLoading = true
    @State private var selectedNode: ServerNode?
    @State private var cookieData: (cookies: [CookieData], targetUrl: String)?
    @State private var showBrowser = false
    @State private var loadingNodeId: Int?
    @State private var errorMsg: String?
    
    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: OTPColors.accent))
                    Text("LOADING SERVERS...")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(OTPColors.textDim)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(nodes) { node in
                        ServerNodeCard(
                            node: node,
                            isLoading: loadingNodeId == node.id,
                            onTap: { handleNodeTap(node, forceRefresh: false) },
                            onRefresh: { handleNodeTap(node, forceRefresh: true) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
        }
        .background(OTPGradients.background.ignoresSafeArea())
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showBrowser) {
            if let data = cookieData {
                WebBrowserView(cookies: data.cookies, targetUrl: data.targetUrl)
            }
        }
        .task {
            await loadNodes()
        }
        .alert("Error", isPresented: .constant(errorMsg != nil)) {
            Button("OK") { errorMsg = nil }
        } message: {
            Text(errorMsg ?? "")
        }
    }
    
    private func loadNodes() async {
        do {
            nodes = try await api.loadNodes(appId: app.id)
            isLoading = false
        } catch {
            errorMsg = error.localizedDescription
            isLoading = false
        }
    }
    
    private func handleNodeTap(_ node: ServerNode, forceRefresh: Bool) {
        guard node.can_access && node.is_working else { return }
        
        Task {
            loadingNodeId = node.id
            do {
                let data = try await api.fetchCookie(nodeId: node.id, forceRefresh: forceRefresh)
                self.cookieData = data
                self.showBrowser = true
            } catch {
                errorMsg = error.localizedDescription
            }
            loadingNodeId = nil
        }
    }
}

// MARK: - Server Node Card

struct ServerNodeCard: View {
    let node: ServerNode
    let isLoading: Bool
    let onTap: () -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .shadow(color: statusColor.opacity(0.5), radius: 4)
            
            // Server info
            VStack(alignment: .leading, spacing: 3) {
                Text(node.server_name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(node.can_access ? OTPColors.textPrimary : OTPColors.textDim)
                
                Text(statusLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: OTPColors.accent))
                    .scaleEffect(0.8)
            } else if node.can_access && node.is_working {
                // Refresh button
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundColor(OTPColors.textDim)
                        .frame(width: 32, height: 32)
                        .background(OTPColors.bgPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(OTPColors.glassBorder, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                
                // Go arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(OTPColors.textDim)
            } else if !node.can_access {
                // Lock badge
                Text(node.lock_app ?? "LOCKED")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(OTPColors.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(OTPColors.warning.opacity(0.1))
                    .clipShape(Capsule())
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(OTPColors.textDim)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassCard(radius: 14)
        .opacity(node.can_access ? 1 : 0.6)
        .onTapGesture(perform: onTap)
    }
    
    private var statusColor: Color {
        if !node.can_access { return OTPColors.warning }
        return node.is_working ? OTPColors.success : OTPColors.danger
    }
    
    private var statusLabel: String {
        if !node.can_access { return node.lock_msg ?? "LOCKED" }
        return node.is_working ? "ONLINE" : "MAINTENANCE"
    }
}
