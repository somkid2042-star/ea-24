import Foundation

struct Transaction: Codable, Identifiable {
    let id: Int
    let amount: Double
    let type: String      // "income" or "expense"
    let category: String
    let category_id: Int?
    let note: String
    let date: String      // "2026-04-13"
    let icon: String
    let color: String
    
    var isIncome: Bool { type == "income" }
    
    var displayDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}

struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let icon: String
    let color: String
    
    var isIncome: Bool { type == "income" }
}

struct CashflowSummary: Codable {
    let income: Double
    let expense: Double
    let balance: Double
    let month: Int
    let year: Int
    let top_categories: [TopCategory]
    let daily: [DailyData]
}

struct TopCategory: Codable, Identifiable {
    var id: String { category }
    let category: String
    let icon: String
    let color: String
    let total: Double
}

struct DailyData: Codable, Identifiable {
    var id: String { "\(date)-\(type)" }
    let date: String
    let type: String
    let total: Double
}
