import SwiftUI

// MARK: - OTP24 Premium Dark Theme

enum OTPColors {
    static let bgPrimary = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let bgSecondary = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let bgCard = Color(red: 0.12, green: 0.12, blue: 0.14)
    
    static let accent = Color(red: 1.0, green: 0.37, blue: 0.0) // OTP Orange
    static let accentLight = Color(red: 1.0, green: 0.55, blue: 0.2)
    
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textDim = Color.white.opacity(0.35)
    
    static let success = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let danger = Color(red: 1.0, green: 0.30, blue: 0.34)
    static let warning = Color(red: 0.95, green: 0.77, blue: 0.06)
    
    static let glassBorder = Color.white.opacity(0.08)
    static let cacheBorder = Color(red: 0.18, green: 0.80, blue: 0.44).opacity(0.5)
}

enum OTPGradients {
    static var background: LinearGradient {
        LinearGradient(
            colors: [OTPColors.bgPrimary, Color(red: 0.04, green: 0.04, blue: 0.06)],
            startPoint: .top, endPoint: .bottom
        )
    }
    
    static var accent: LinearGradient {
        LinearGradient(
            colors: [OTPColors.accent, OTPColors.accentLight],
            startPoint: .leading, endPoint: .trailing
        )
    }
    
    static var card: LinearGradient {
        LinearGradient(
            colors: [OTPColors.bgCard, OTPColors.bgCard.opacity(0.6)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var radius: CGFloat = 16
    var hasCacheBorder: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(OTPColors.bgCard.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        hasCacheBorder ? OTPColors.cacheBorder : OTPColors.glassBorder,
                        lineWidth: hasCacheBorder ? 1.5 : 0.5
                    )
            )
            .shadow(color: hasCacheBorder ? OTPColors.success.opacity(0.15) : .black.opacity(0.2),
                    radius: hasCacheBorder ? 8 : 6, x: 0, y: 4)
    }
}

extension View {
    func glassCard(radius: CGFloat = 16, hasCacheBorder: Bool = false) -> some View {
        modifier(GlassCard(radius: radius, hasCacheBorder: hasCacheBorder))
    }
}
