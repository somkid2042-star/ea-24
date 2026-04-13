import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var state: AppState
    @Binding var showSideMenu: Bool
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // ══════════════════════════════════════════
                //  PURPLE HEADER ZONE
                // ══════════════════════════════════════════
                ZStack(alignment: .top) {
                    // Purple gradient background (extends behind status bar)
                    LinearGradient(
                        colors: [FA.primaryDark, FA.primary, FA.primaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 370)
                    .padding(.top, -100) // extend above safe area
                    .ignoresSafeArea(edges: .top)
                    
                    VStack(spacing: 0) {
                        // ── Top bar: hamburger + "Finapp" + bell + avatar ──
                        HStack {
                            Button(action: { showSideMenu.toggle() }) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 22, weight: .light))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // App title with icon
                            HStack(spacing: 6) {
                                Image(systemName: "diamond")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(.white)
                                Text("Cashflow")
                                    .font(.camingo(20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Bell with badge
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
                            .padding(.trailing, 12)
                            
                            // Avatar with badge
                            ZStack(alignment: .topTrailing) {
                                Image("ProfileAvatar")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                                
                                Text("6")
                                    .font(.camingo(9, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(FA.exchange)
                                    .clipShape(Circle())
                                    .offset(x: 4, y: -4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // ── Total Balance Card ──
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Balance")
                                        .font(.camingo(14, weight: .medium))
                                        .foregroundColor(FA.textMedium)
                                    
                                    Text("$ \((state.summary?.balance ?? 2562.50).money)")
                                        .font(.camingo(36, weight: .bold))
                                        .foregroundColor(FA.textDark)
                                }
                                
                                Spacer()
                                
                                // + button
                                Button(action: { state.showAddSheet = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 22, weight: .light))
                                        .foregroundColor(FA.primary)
                                        .frame(width: 48, height: 48)
                                        .background(FA.primary.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // ── Quick Actions: Withdraw, Send, Cards, Exchange ──
                            HStack(spacing: 0) {
                                quickAction(icon: "arrow.down", label: "Withdraw", color: FA.withdraw)
                                quickAction(icon: "arrow.right", label: "Send", color: FA.send)
                                quickAction(icon: "creditcard", label: "Cards", color: FA.cards)
                                quickAction(icon: "arrow.up.arrow.down", label: "Exchange", color: FA.exchange)
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                        }
                        .background(FA.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
                
                // ══════════════════════════════════════════
                //  STATS GRID (Income, Expenses, Bills, Savings)
                // ══════════════════════════════════════════
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    statCard(title: "Income", amount: state.summary?.income ?? 552.95, color: FA.incomeGreen)
                    statCard(title: "Expenses", amount: state.summary?.expense ?? 86.45, color: FA.expenseRed)
                    statCard(title: "Total Bills", amount: 53.25, color: FA.textDark)
                    statCard(title: "Savings", amount: 120.99, color: FA.textDark)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                
                // ══════════════════════════════════════════
                //  TRANSACTIONS
                // ══════════════════════════════════════════
                HStack {
                    Text("Transactions")
                        .font(.camingo(20, weight: .bold))
                        .foregroundColor(FA.textDark)
                    
                    Spacer()
                    
                    Button(action: { state.selectedTab = .transactions }) {
                        Text("View All")
                            .font(.camingo(14, weight: .medium))
                            .foregroundColor(FA.viewAll)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                
                VStack(spacing: 0) {
                    ForEach(Array(state.transactions.prefix(5).enumerated()), id: \.element.id) { idx, txn in
                        if idx > 0 {
                            Divider()
                                .padding(.leading, 72)
                        }
                        transactionRow(txn)
                    }
                    
                    if state.transactions.isEmpty {
                        // Mock transactions
                        mockTransactionRow(name: "Amazon", sub: "Shopping", amount: -150, color: "#F5A623", icon: "bag")
                        Divider().padding(.leading, 72)
                        mockTransactionRow(name: "Salary", sub: "Monthly", amount: 3500, color: "#34C759", icon: "dollarsign.circle")
                        Divider().padding(.leading, 72)
                        mockTransactionRow(name: "Netflix", sub: "Entertainment", amount: -15.99, color: "#E74268", icon: "play.rectangle")
                    }
                }
                .faCard(16)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // ══════════════════════════════════════════
                //  MY CARDS
                // ══════════════════════════════════════════
                HStack {
                    Text("My Cards")
                        .font(.camingo(20, weight: .bold))
                        .foregroundColor(FA.textDark)
                    Spacer()
                    Text("View All")
                        .font(.camingo(14, weight: .medium))
                        .foregroundColor(FA.viewAll)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        mockCardBlock(color: FA.primary, balance: "$ 1,256,90", number: "9905", expiry: "12 / 25")
                        mockCardBlock(color: FA.textDark, balance: "$ 1,256,90", number: "9905", expiry: "12 / 25")
                        mockCardBlock(color: FA.textMedium, balance: "$ 1,256,90", number: "9905", expiry: "12 / 25")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                
                // ══════════════════════════════════════════
                //  SEND MONEY
                // ══════════════════════════════════════════
                HStack {
                    Text("Send Money")
                        .font(.camingo(20, weight: .bold))
                        .foregroundColor(FA.textDark)
                    Spacer()
                    Text("Add New")
                        .font(.camingo(14, weight: .medium))
                        .foregroundColor(FA.viewAll)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        mockAvatar(name: "Jurrien")
                        mockAvatar(name: "Elwin")
                        mockAvatar(name: "Alma")
                        mockAvatar(name: "Justine")
                        mockAvatar(name: "Maria")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
                
                // ══════════════════════════════════════════
                //  MONTHLY BILLS
                // ══════════════════════════════════════════
                HStack {
                    Text("Monthly Bills")
                        .font(.camingo(20, weight: .bold))
                        .foregroundColor(FA.textDark)
                    Spacer()
                    Text("View All")
                        .font(.camingo(14, weight: .medium))
                        .foregroundColor(FA.viewAll)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        mockBillBox(title: "Prime Monthly Subscription", amount: 14)
                        mockBillBox(title: "Music Monthly Subscription", amount: 9)
                        mockBillBox(title: "Monthly Health Insurance", amount: 299)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                
                // ══════════════════════════════════════════
                //  SAVING GOALS
                // ══════════════════════════════════════════
                HStack {
                    Text("Saving Goals")
                        .font(.camingo(20, weight: .bold))
                        .foregroundColor(FA.textDark)
                    Spacer()
                    Text("View All")
                        .font(.camingo(14, weight: .medium))
                        .foregroundColor(FA.viewAll)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                
                VStack(spacing: 16) {
                    mockSavingGoal(title: "Gaming Console", category: "Gaming", amount: 499, percent: 85)
                    mockSavingGoal(title: "New House", category: "Living", amount: 100000, percent: 55)
                    mockSavingGoal(title: "Sport Car", category: "Lifestyle", amount: 42500, percent: 15)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .background(FA.bg.ignoresSafeArea())
        .refreshable { await state.loadAll() }
    }
    
    // MARK: - Quick Action Button
    private func quickAction(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(color)
                .clipShape(Circle())
            
            Text(label)
                .font(.camingo(12, weight: .medium))
                .foregroundColor(FA.textMedium)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Stat Card (Income / Expenses / Bills / Savings)
    private func statCard(title: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.camingo(14, weight: .medium))
                .foregroundColor(FA.textMedium)
            
            Text("$ \(amount.money)")
                .font(.camingo(22, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .faCard(16)
    }
    
    // MARK: - Transaction Row
    private func transactionRow(_ txn: Transaction) -> some View {
        HStack(spacing: 14) {
            // Icon
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
                
                Text(txn.note.isEmpty ? txn.type.capitalized : txn.note)
                    .font(.camingo(13))
                    .foregroundColor(FA.textLight)
            }
            
            Spacer()
            
            Text("\(txn.isIncome ? "+ " : "- ")$\u{00a0}\(Int(txn.amount))")
                .font(.camingo(16, weight: .bold))
                .foregroundColor(txn.isIncome ? FA.incomeGreen : FA.expenseRed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Mock Transaction Row
    private func mockTransactionRow(name: String, sub: String, amount: Double, color: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color(hex: color))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.camingo(15, weight: .semibold))
                    .foregroundColor(FA.textDark)
                Text(sub)
                    .font(.camingo(13))
                    .foregroundColor(FA.textLight)
            }
            
            Spacer()
            
            Text("\(amount >= 0 ? "+ " : "- ")$\u{00a0}\(abs(Int(amount)))")
                .font(.camingo(16, weight: .bold))
                .foregroundColor(amount >= 0 ? FA.incomeGreen : FA.expenseRed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - UI Components for Finapp Dashboard
    
    private func mockCardBlock(color: Color, balance: String, number: String, expiry: String) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BALANCE")
                        .font(.camingo(10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    Text(balance)
                        .font(.camingo(24, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(90))
            }
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Card Number")
                        .font(.camingo(10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("•••• \(number)")
                        .font(.camingo(14, weight: .medium))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expiry")
                        .font(.camingo(10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text(expiry)
                        .font(.camingo(14, weight: .medium))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("CCV")
                        .font(.camingo(10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("553")
                        .font(.camingo(14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(24)
        .frame(width: 300)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func mockAvatar(name: String) -> some View {
        VStack(spacing: 8) {
            Image("ProfileAvatar")
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            Text(name)
                .font(.camingo(13, weight: .semibold))
                .foregroundColor(FA.textDark)
        }
    }
    
    private func mockBillBox(title: String, amount: Double) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "cube.box")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(FA.primary)
                .frame(width: 60, height: 60)
                .background(FA.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            Text("$ \(Int(amount))")
                .font(.camingo(24, weight: .bold))
                .foregroundColor(FA.textDark)
            
            Text(title)
                .font(.camingo(13))
                .foregroundColor(FA.textMedium)
                .multilineTextAlignment(.center)
                .frame(height: 36)
            
            Button(action: {}) {
                Text("PAY NOW")
                    .font(.camingo(12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(FA.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .frame(width: 140)
        .padding(16)
        .background(FA.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private func mockSavingGoal(title: String, category: String, amount: Double, percent: CGFloat) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.camingo(16, weight: .bold))
                        .foregroundColor(FA.textDark)
                    Text(category)
                        .font(.camingo(12))
                        .foregroundColor(FA.textMedium)
                }
                Spacer()
                Text("$ \(Int(amount))")
                    .font(.camingo(18, weight: .bold))
                    .foregroundColor(FA.textDark)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FA.textLight.opacity(0.2))
                        .frame(height: 12)
                    Capsule()
                        .fill(FA.primary)
                        .frame(width: geo.size.width * (percent / 100), height: 12)
                    Text("\(Int(percent))%")
                        .font(.camingo(8, weight: .bold))
                        .foregroundColor(.white)
                        .position(x: (geo.size.width * (percent / 100)) - 12, y: 6)
                }
            }
            .frame(height: 12)
        }
    }
}

#Preview {
    DashboardView(showSideMenu: .constant(false))
        .environmentObject(AppState())
}
