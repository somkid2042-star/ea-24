import Foundation

final class APIService: Sendable {
    static let shared = APIService()
    private init() {}
    
    // MARK: - Fetch Summary
    func fetchSummary(baseURL: String, month: Int, year: Int) async -> CashflowSummary? {
        guard let url = URL(string: "\(baseURL)/api/cashflow/summary?month=\(month)&year=\(year)") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(CashflowSummary.self, from: data)
        } catch {
            print("[API] fetchSummary error: \(error)")
            return nil
        }
    }
    
    // MARK: - Fetch Transactions
    func fetchTransactions(baseURL: String, month: Int, year: Int) async -> [Transaction] {
        guard let url = URL(string: "\(baseURL)/api/cashflow/transactions?month=\(month)&year=\(year)") else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode([Transaction].self, from: data)
        } catch {
            print("[API] fetchTransactions error: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch Categories
    func fetchCategories(baseURL: String) async -> [Category] {
        guard let url = URL(string: "\(baseURL)/api/cashflow/categories") else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode([Category].self, from: data)
        } catch {
            print("[API] fetchCategories error: \(error)")
            return []
        }
    }
    
    // MARK: - Add Transaction
    func addTransaction(baseURL: String, amount: Double, type: String, category: String, categoryId: Int?, note: String, date: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/cashflow/transactions") else { return false }
        
        var body: [String: Any] = [
            "amount": amount,
            "type": type,
            "category": category,
            "note": note,
            "date": date
        ]
        if let cid = categoryId { body["category_id"] = cid }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 201
        } catch {
            print("[API] addTransaction error: \(error)")
            return false
        }
    }
    
    // MARK: - Delete Transaction
    func deleteTransaction(baseURL: String, id: Int) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/cashflow/transactions/\(id)") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            print("[API] deleteTransaction error: \(error)")
            return false
        }
    }
}
