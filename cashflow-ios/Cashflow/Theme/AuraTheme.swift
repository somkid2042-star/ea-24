import SwiftUI

// MARK: - Finapp Design System (Pixel-perfect from screenshot)

enum FA {
    // Primary purple gradient
    static let primary = Color(hex: "#5B4FE6")
    static let primaryDark = Color(hex: "#4A3FD4")
    static let primaryLight = Color(hex: "#7B6FF0")
    
    // Background
    static let bg = Color(hex: "#F5F5FA")
    static let surface = Color.white
    
    // Quick Action button colors
    static let withdraw = Color(hex: "#E74268")   // Red/Pink
    static let send = Color(hex: "#3B3B5A")        // Dark navy
    static let cards = Color(hex: "#34C759")       // Green
    static let exchange = Color(hex: "#F5A623")    // Amber/Gold
    
    // Stat card text colors
    static let incomeGreen = Color(hex: "#34C759")
    static let expenseRed = Color(hex: "#E74268")
    
    // Text
    static let textDark = Color(hex: "#1E1E2D")
    static let textMedium = Color(hex: "#6E6E82")
    static let textLight = Color(hex: "#9E9EB8")
    
    // Other
    static let border = Color(hex: "#EBEBF0")
    static let notifBadge = Color(hex: "#FF6B6B")
    static let viewAll = Color(hex: "#5B4FE6")
    
    // Tab bar
    static let tabActive = Color(hex: "#5B4FE6")
    static let tabInactive = Color(hex: "#9E9EB8")
    
    // Card shadow
    static func cardShadow() -> some View {
        Color.black.opacity(0.04)
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Number Formatter

extension Double {
    var money: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: self)) ?? "0.00"
    }
}

// MARK: - Finapp Card Style

struct FACard: ViewModifier {
    var radius: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .background(FA.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func faCard(_ radius: CGFloat = 16) -> some View {
        modifier(FACard(radius: radius))
    }
}

// MARK: - CamingoCode Font

extension Font {
    static func camingo(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .heavy, .black, .semibold:
            return .custom("CamingoCode-Bold", size: size)
        default:
            return .custom("CamingoCode-Regular", size: size)
        }
    }
    
    static func camingoItalic(_ size: CGFloat, bold: Bool = false) -> Font {
        bold
            ? .custom("CamingoCode-BoldItalic", size: size)
            : .custom("CamingoCode-Italic", size: size)
    }
}
