import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var state: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // ── Purple header ──
            ZStack {
                FA.primary
                    .padding(.top, -100)
                    .ignoresSafeArea(edges: .top)
                HStack {
                    Spacer()
                    Text("Analytics")
                        .font(.camingo(20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .overlay(alignment: .trailing) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white)
                        
                        Text("4")
                            .font(.camingo(9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(FA.notifBadge)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 8)
            }
            .frame(height: 56)
            
            ScrollView {
                VStack(spacing: 20) {
                    // ── Summary Card ──
                    VStack(spacing: 16) {
                        HStack {
                            Text("Monthly Overview")
                                .font(.camingo(17, weight: .bold))
                                .foregroundColor(FA.textDark)
                            Spacer()
                            
                            // Month selector
                            HStack(spacing: 4) {
                                Button(action: { state.changeMonth(by: -1) }) {
                                    Image(systemName: "chevron.left")
                                        .font(.camingo(12, weight: .semibold))
                                        .foregroundColor(FA.primary)
                                }
                                
                                Text(monthName)
                                    .font(.camingo(14, weight: .semibold))
                                    .foregroundColor(FA.primary)
                                    .frame(width: 80)
                                
                                Button(action: { state.changeMonth(by: 1) }) {
                                    Image(systemName: "chevron.right")
                                        .font(.camingo(12, weight: .semibold))
                                        .foregroundColor(FA.primary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(FA.primary.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        
                        // Bar chart-like summary
                        HStack(spacing: 16) {
                            summaryBar(title: "Income", amount: state.summary?.income ?? 0, color: FA.incomeGreen, maxH: 120)
                            summaryBar(title: "Expense", amount: state.summary?.expense ?? 0, color: FA.expenseRed, maxH: 120)
                            summaryBar(title: "Balance", amount: state.summary?.balance ?? 0, color: FA.primary, maxH: 120)
                        }
                    }
                    .padding(20)
                    .faCard(16)
                    
                    // ── Top Categories ──
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Top Categories")
                            .font(.camingo(17, weight: .bold))
                            .foregroundColor(FA.textDark)
                        
                        if let cats = state.summary?.top_categories, !cats.isEmpty {
                            ForEach(cats.prefix(5)) { cat in
                                HStack(spacing: 14) {
                                    Image(systemName: cat.icon.isEmpty ? "tag" : cat.icon)
                                        .font(.system(size: 18, weight: .light))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color(hex: cat.color.isEmpty ? "#F5A623" : cat.color))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    
                                    Text(cat.category)
                                        .font(.camingo(15, weight: .medium))
                                        .foregroundColor(FA.textDark)
                                    
                                    Spacer()
                                    
                                    Text("$ \(cat.total.money)")
                                        .font(.camingo(15, weight: .bold))
                                        .foregroundColor(FA.expenseRed)
                                }
                            }
                        } else {
                            Text("No data yet")
                                .font(.camingo(14))
                                .foregroundColor(FA.textLight)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }
                    .padding(20)
                    .faCard(16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
            .background(FA.bg)
            .refreshable { await state.loadAll() }
        }
        .background(FA.primary.ignoresSafeArea(edges: .top))
    }
    
    private var monthName: String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        var dc = DateComponents()
        dc.month = state.selectedMonth
        dc.year = state.selectedYear
        return f.string(from: Calendar.current.date(from: dc) ?? Date())
    }
    
    private func summaryBar(title: String, amount: Double, color: Color, maxH: CGFloat) -> some View {
        let maxVal = max(state.summary?.income ?? 1, state.summary?.expense ?? 1, abs(state.summary?.balance ?? 1), 1)
        let ratio = min(abs(amount) / maxVal, 1.0)
        
        return VStack(spacing: 8) {
            Spacer()
            
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color.opacity(0.2))
                .frame(height: max(maxH * ratio, 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color)
                        .frame(height: max(maxH * ratio * 0.7, 6))
                    , alignment: .bottom
                )
            
            Text("$\(amount.money)")
                .font(.camingo(12, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.camingo(11, weight: .medium))
                .foregroundColor(FA.textMedium)
        }
        .frame(maxWidth: .infinity)
        .frame(height: maxH + 50)
    }
}

#Preview {
    AnalyticsView().environmentObject(AppState())
}
