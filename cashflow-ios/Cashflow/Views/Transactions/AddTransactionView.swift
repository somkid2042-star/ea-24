import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var type: String = "expense"
    @State private var amount: String = ""
    @State private var selectedCategory: Category?
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var isSaving = false
    @FocusState private var amountFocused: Bool
    
    private var filteredCategories: [Category] {
        state.categories.filter { $0.type == type }
    }
    
    private var isValid: Bool {
        guard let amt = Double(amount), amt > 0 else { return false }
        return selectedCategory != nil
    }
    
    var body: some View {
        NavigationView {
            ListView {
                // Type selector
                typeSelector
                
                // Amount
                amountSection
                
                // Category
                categorySection
                
                // Date
                dateSection
                
                // Note
                noteSection
                
                // Submit
                submitButton
            }
            .background(FA.bg)
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.camingo(16, weight: .semibold))
                            .foregroundColor(FA.textDark)
                    }
                }
            }
        }
        .onAppear { amountFocused = true }
    }
    
    // Type selector (Finapp style)
    private var typeSelector: some View {
        HStack(spacing: 16) {
            optionBtn("Expense", icon: "arrow.up.circle.fill", value: "expense")
            optionBtn("Income", icon: "arrow.down.circle.fill", value: "income")
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    private func optionBtn(_ label: String, icon: String, value: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                type = value; selectedCategory = nil
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.camingo(28))
                    .foregroundColor(type == value ? .white : FA.textDark)
                Text(label)
                    .font(.camingo(13, weight: .semibold))
                    .foregroundColor(type == value ? .white : FA.textDark)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                type == value
                    ? AnyShapeStyle(LinearGradient(colors: [FA.primary, FA.primaryLight], startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(FA.surface)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: type == value ? FA.primary.opacity(0.3) : .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    // Amount
    private var amountSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.camingo(28))
                .foregroundColor(FA.primary)
            
            TextField("Amount", text: $amount)
                .font(.camingo(20, weight: .semibold))
                .keyboardType(.decimalPad)
                .focused($amountFocused)
                .foregroundColor(FA.textDark)
                .tint(FA.primary)
        }
        .padding(16)
        .faCard(12)
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // Category grid
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATEGORY")
                .font(.camingo(12, weight: .bold))
                .foregroundColor(FA.textLight)
                .tracking(0.3)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(filteredCategories) { cat in
                    Button(action: { withAnimation { selectedCategory = cat } }) {
                        VStack(spacing: 6) {
                            Image(systemName: cat.icon)
                                .font(.camingo(20))
                                .foregroundColor(selectedCategory?.id == cat.id ? .white : Color(hex: cat.color))
                                .frame(width: 48, height: 48)
                                .background(
                                    selectedCategory?.id == cat.id
                                        ? Color(hex: cat.color)
                                        : Color(hex: cat.color).opacity(0.12)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            Text(cat.name)
                                .font(.camingo(9, weight: .semibold))
                                .foregroundColor(FA.textMedium)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // Date
    private var dateSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.camingo(22))
                .foregroundColor(FA.primary)
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(FA.primary)
        }
        .padding(16)
        .faCard(12)
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // Note
    private var noteSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil.line")
                .font(.camingo(22))
                .foregroundColor(FA.primary)
            
            TextField("Note (optional)", text: $note)
                .font(.camingo(15))
                .foregroundColor(FA.textDark)
                .tint(FA.primary)
        }
        .padding(16)
        .faCard(12)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }
    
    // Submit
    private var submitButton: some View {
        Button(action: save) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.camingo(16))
                    Text("Save Transaction")
                        .font(.camingo(15, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isValid
                    ? LinearGradient(colors: [FA.primary, FA.primaryLight], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [FA.textLight, FA.textLight], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: isValid ? FA.primary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!isValid || isSaving)
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
    
    private func save() {
        guard let amt = Double(amount), let cat = selectedCategory else { return }
        isSaving = true
        Task {
            let ok = await state.addTransaction(
                amount: amt, type: type,
                category: cat.name, categoryId: cat.id,
                note: note, date: date
            )
            isSaving = false
            if ok { dismiss() }
        }
    }
}

// Simple ListView wrapper
struct ListView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ScrollView { VStack(spacing: 0) { content } }
    }
}

#Preview {
    AddTransactionView().environmentObject(AppState())
}
