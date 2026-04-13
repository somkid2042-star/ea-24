import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    // MARK: - Server Config (same as EA24)
    @AppStorage("serverHost") var serverHost: String = "35.187.147.242"
    @AppStorage("httpPort") var httpPort: String = "4173"
    
    // MARK: - Data
    @Published var summary: CashflowSummary?
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var selectedMonth: Int
    @Published var selectedYear: Int
    @Published var selectedTab: TabItem = .dashboard
    @Published var showAddSheet = false
    
    var baseURL: String { "http://\(serverHost):\(httpPort)" }
    
    init() {
        let now = Calendar.current.dateComponents([.month, .year], from: Date())
        self.selectedMonth = now.month ?? 4
        self.selectedYear = now.year ?? 2026
    }
    
    func loadAll() async {
        isLoading = true
        async let s = APIService.shared.fetchSummary(baseURL: baseURL, month: selectedMonth, year: selectedYear)
        async let t = APIService.shared.fetchTransactions(baseURL: baseURL, month: selectedMonth, year: selectedYear)
        async let c = APIService.shared.fetchCategories(baseURL: baseURL)
        
        self.summary = await s
        self.transactions = await t
        self.categories = await c
        isLoading = false
    }
    
    func addTransaction(amount: Double, type: String, category: String, categoryId: Int?, note: String, date: Date) async -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        
        let ok = await APIService.shared.addTransaction(
            baseURL: baseURL,
            amount: amount, type: type,
            category: category, categoryId: categoryId,
            note: note, date: dateStr
        )
        if ok {
            await loadAll()
        }
        return ok
    }
    
    func deleteTransaction(_ id: Int) async {
        let _ = await APIService.shared.deleteTransaction(baseURL: baseURL, id: id)
        await loadAll()
    }
    
    func changeMonth(by delta: Int) {
        var m = selectedMonth + delta
        var y = selectedYear
        if m < 1 { m = 12; y -= 1 }
        if m > 12 { m = 1; y += 1 }
        selectedMonth = m
        selectedYear = y
        Task { await loadAll() }
    }
}

// MARK: - Tab

enum TabItem: String, CaseIterable {
    case dashboard = "Dashboard"
    case transactions = "Transactions"
    case analytics = "Analytics"
    case otp24 = "OTP24"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .dashboard: return "chart.pie.fill"
        case .transactions: return "doc.text.fill"
        case .analytics: return "square.grid.2x2.fill"
        case .otp24: return "square.stack.3d.up.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
