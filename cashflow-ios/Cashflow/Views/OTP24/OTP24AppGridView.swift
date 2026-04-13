import SwiftUI

struct OTP24AppGridView: View {
    let apps: [OTP24App]
    let onSelect: (OTP24App) -> Void
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(apps) { app in
                appCard(app)
                    .onTapGesture {
                        if !app.is_locked {
                            onSelect(app)
                        }
                    }
            }
        }
    }
    
    // MARK: - App Card
    
    @ViewBuilder
    private func appCard(_ app: OTP24App) -> some View {
        VStack(spacing: 6) {
            ZStack {
                // Icon
                AsyncImage(url: URL(string: app.icon_url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    default:
                        Image(systemName: app.iconSystemName)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: app.tierColor), Color(hex: app.tierColor).opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                
                // Lock overlay
                if app.is_locked {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.black.opacity(0.4))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            
            Text(app.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(app.is_locked ? FA.textLight : FA.textDark)
                .lineLimit(1)
            
            // Tier badge
            if app.is_locked, let req = app.requirement {
                Text(req)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color(hex: app.tierColor))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(FA.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(app.is_locked ? 0.02 : 0.06), radius: 6, x: 0, y: 2)
        .opacity(app.is_locked ? 0.7 : 1)
    }
}
