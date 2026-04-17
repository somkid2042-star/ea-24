import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var api: APIService
    
    var body: some View {
        VStack(spacing: 0) {
            // Account Status Bar
            AccountStatusBar()
            
            // App Grid
            AppGridView()
        }
    }
}

// MARK: - Account Status Bar

struct AccountStatusBar: View {
    @EnvironmentObject var api: APIService
    
    var body: some View {
        HStack(spacing: 0) {
            // Status dot
            Circle()
                .fill(OTPColors.success)
                .frame(width: 8, height: 8)
                .shadow(color: OTPColors.success.opacity(0.6), radius: 4)
            
            Spacer().frame(width: 12)
            
            // Plan
            StatusItem(label: "PLAN", value: api.accountData?.packageType.uppercased() ?? "---", color: OTPColors.accent)
            
            Divider()
                .frame(height: 22)
                .background(OTPColors.glassBorder)
                .padding(.horizontal, 12)
            
            // Usage
            let used = api.accountData?.usedToday ?? 0
            let limit = api.accountData?.dailyLimit ?? 0
            StatusItem(label: "USAGE", value: "\(used)/\(limit > 0 ? "\(limit)" : "---")")
            
            Divider()
                .frame(height: 22)
                .background(OTPColors.glassBorder)
                .padding(.horizontal, 12)
            
            // Expiry
            StatusItem(label: "EXPIRY", value: expiryText, color: expiryColor)
            
            Spacer()
            
            // Logout
            Button(action: { api.logout() }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14))
                    .foregroundColor(OTPColors.textDim)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(OTPColors.bgSecondary.opacity(0.95))
    }
    
    private var expiryText: String {
        guard let dateStr = api.accountData?.expiryDate else { return "---" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days <= 0 { return "EXPIRED" }
        return "\(days) DAYS"
    }
    
    private var expiryColor: Color {
        guard let dateStr = api.accountData?.expiryDate else { return OTPColors.textSecondary }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return OTPColors.textSecondary }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days <= 3 { return OTPColors.danger }
        if days <= 7 { return OTPColors.warning }
        return OTPColors.textSecondary
    }
}

struct StatusItem: View {
    let label: String
    let value: String
    var color: Color = OTPColors.textPrimary
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1)
                .foregroundColor(OTPColors.textDim)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
    }
}
