import SwiftUI

struct AppGridView: View {
    @EnvironmentObject var api: APIService
    @State private var selectedApp: OTPApp?
    @State private var searchText = ""
    
    private var filteredApps: [OTPApp] {
        if searchText.isEmpty { return api.apps }
        return api.apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(OTPColors.textDim)
                    TextField("Search apps...", text: $searchText)
                        .font(.system(size: 14))
                        .foregroundColor(OTPColors.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(OTPColors.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(OTPColors.glassBorder, lineWidth: 0.5)
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // App Grid
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(filteredApps) { app in
                        AppCardView(app: app, hasCached: api.cachedAppIds.contains(app.id))
                            .onTapGesture {
                                if app.is_locked {
                                    // Show lock toast
                                } else {
                                    selectedApp = app
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
            .background(Color.clear)
            .navigationDestination(item: $selectedApp) { app in
                ServerListView(app: app)
            }
        }
    }
}

// MARK: - App Card

struct AppCardView: View {
    let app: OTPApp
    let hasCached: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                // Icon
                AsyncImage(url: URL(string: app.icon_url)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        RoundedRectangle(cornerRadius: 14)
                            .fill(OTPColors.bgSecondary)
                            .overlay(
                                Image(systemName: "app.fill")
                                    .foregroundColor(OTPColors.textDim)
                            )
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            hasCached ? OTPColors.cacheBorder : OTPColors.glassBorder,
                            lineWidth: hasCached ? 1.5 : 0.5
                        )
                )
                .shadow(color: hasCached ? OTPColors.success.opacity(0.2) : .clear, radius: 6)
                
                // Cache dot
                if hasCached {
                    Circle()
                        .fill(OTPColors.success)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle().strokeBorder(OTPColors.bgPrimary, lineWidth: 2)
                        )
                        .shadow(color: OTPColors.success.opacity(0.6), radius: 3)
                        .offset(x: 2, y: 2)
                }
                
                // Lock overlay
                if app.is_locked {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.black.opacity(0.5))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
            }
            
            // Name
            Text(app.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(app.is_locked ? OTPColors.textDim : OTPColors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 28)
        }
        .frame(maxWidth: .infinity)
    }
}
