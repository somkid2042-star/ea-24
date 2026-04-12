import SwiftUI

// MARK: - Aura Minimalist Premium Design System

enum AuraColors {
    // Pure minimalist dark theme
    static let backgroundStart = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let backgroundEnd = Color(red: 0.02, green: 0.02, blue: 0.03)
    
    static let glassBackground = Color.white.opacity(0.04)
    static let glassBorder = Color.white.opacity(0.1)
    
    // Accents
    static let accent = Color(red: 0.35, green: 0.85, blue: 0.65) // Neon Mint
    static let accentGradientEnd = Color(red: 0.20, green: 0.60, blue: 0.90) // Electric Blue
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    
    // Status
    static let error = Color(red: 1.0, green: 0.4, blue: 0.45)
    static let success = Color(red: 0.4, green: 1.0, blue: 0.6)
}

enum AuraGradients {
    static var mainBackground: LinearGradient {
        LinearGradient(
            colors: [AuraColors.backgroundStart, AuraColors.backgroundEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var accentGlow: LinearGradient {
        LinearGradient(
            colors: [AuraColors.accent, AuraColors.accentGradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Modifiers

struct GlassmorphismModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AuraColors.glassBorder, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glass(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassmorphismModifier(cornerRadius: cornerRadius))
    }
}
