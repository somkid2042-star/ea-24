import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var state: AppState
    @State private var selectedFilter = 0
    
    private let filters = ["All", "Income", "Expense"]
    
    private var filteredTransactions: [Transaction] {
        switch selectedFilter {
        case 1: return state.transactions.filter { $0.isIncome }
        case 2: return state.transactions.filter { !$0.isIncome }
        default: return state.transactions
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ── Header (purple bg, centered title) ──
            ZStack {
                FA.primary
                    .padding(.top, -100)
                    .ignoresSafeArea(edges: .top)
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text("Transactions")
                            .font(.camingo(20, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .overlay(alignment: .trailing) {
                        // Notification bell (matching Finapp header)
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
                    
                    // Filter chips
                    HStack(spacing: 12) {
                        ForEach(0..<filters.count, id: \.self) { i in
                            Button(action: { withAnimation { selectedFilter = i } }) {
                                Text(filters[i])
                                    .font(.camingo(14, weight: .semibold))
                                    .foregroundColor(selectedFilter == i ? FA.primary : .white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedFilter == i
                                            ? FA.surface
                                            : Color.white.opacity(0.2)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
            }
            .frame(height: 110)
            
            // ── Transaction List ──
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredTransactions.enumerated()), id: \.element.id) { idx, txn in
                        if idx > 0 {
                            Divider().padding(.leading, 72)
                        }
                        
                        HStack(spacing: 14) {
                            Image(systemName: txn.icon.isEmpty ? "bag" : txn.icon)
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color(hex: txn.color.isEmpty ? "#F5A623" : txn.color))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(txn.category.isEmpty ? txn.type.capitalized : txn.category)
                                    .font(.camingo(15, weight: .semibold))
                                    .foregroundColor(FA.textDark)
                                
                                Text(txn.note.isEmpty ? txn.date : txn.note)
                                    .font(.camingo(13))
                                    .foregroundColor(FA.textLight)
                            }
                            
                            Spacer()
                            
                            Text("\(txn.isIncome ? "+" : "-") $ \(txn.amount.money)")
                                .font(.camingo(15, weight: .bold))
                                .foregroundColor(txn.isIncome ? FA.incomeGreen : FA.expenseRed)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await state.deleteTransaction(txn.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    if filteredTransactions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 40, weight: .ultraLight))
                                .foregroundColor(FA.textLight)
                            Text("No transactions")
                                .font(.camingo(15, weight: .medium))
                                .foregroundColor(FA.textLight)
                        }
                        .padding(.vertical, 60)
                    }
                }
                .faCard(16)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
            .background(FA.bg)
            .refreshable { await state.loadAll() }
        }
        .background(FA.primary.ignoresSafeArea(edges: .top))
    }
}

#Preview {
    TransactionListView().environmentObject(AppState())
}
