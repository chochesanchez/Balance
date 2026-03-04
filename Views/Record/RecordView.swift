import SwiftUI

// MARK: - Record View
struct RecordView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    var initialType: TransactionType?
    var initialIsRecurring: Bool

    @State private var amount = ""
    @State private var selectedType: TransactionType?
    @State private var selectedAccountId: UUID?
    @State private var selectedCategoryId: UUID?
    @State private var toAccountId: UUID?
    @State private var title = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var showingSuccess = false
    @State private var showingAddAccount = false
    @State private var showingAddCategory = false
    @State private var showCurrencyPicker = false
    
    @State private var isRecurring = false
    @State private var recurringFrequency: RecurringFrequency = .monthly
    @State private var recurringEndDate: Date? = nil
    @State private var hasEndDate = false
    @State private var notifyDaysBefore = 1
    @FocusState private var amountFocused: Bool
    
    init(viewModel: BalanceViewModel, initialType: TransactionType? = nil, initialIsRecurring: Bool = false) {
        self.viewModel = viewModel
        self.initialType = initialType
        self.initialIsRecurring = initialIsRecurring
        _selectedType = State(initialValue: initialType)
        _isRecurring = State(initialValue: initialIsRecurring)
    }
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    AmountInputSection(amount: $amount, isFocused: $amountFocused)
                    
                    RecordCurrencyRow(
                        currency: viewModel.appState.selectedCurrency,
                        onTap: { showCurrencyPicker = true }
                    )
                    
                    TypeSelectorCard(selectedType: $selectedType)
                    
                    AccountSelectionCard(
                        viewModel: viewModel,
                        selectedAccountId: $selectedAccountId,
                        toAccountId: $toAccountId,
                        isTransfer: selectedType == .transfer,
                        showingAddAccount: $showingAddAccount
                    )
                    
                    if selectedType != nil && selectedType != .transfer {
                        CategorySelectionCard(
                            viewModel: viewModel,
                            selectedCategoryId: $selectedCategoryId,
                            categoryType: selectedType == .income ? .income : .expense,
                            showingAddCategory: $showingAddCategory
                        )
                        .transition(.asymmetric(
                            insertion: .push(from: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    } else if selectedType == nil {
                        RecordPlaceholderCard(label: "Category", hint: "Select a type first")
                    }
                    
                    if selectedType == .income || selectedType == .expense {
                        RecurringCard(
                            isRecurring: $isRecurring,
                            frequency: $recurringFrequency,
                            hasEndDate: $hasEndDate,
                            endDate: $recurringEndDate,
                            notifyDays: $notifyDaysBefore
                        )
                        .transition(.push(from: .bottom).combined(with: .opacity))
                    }
                    
                    DetailsCard(title: $title, note: $note, date: $date)
                    
                    Button(action: recordTransaction) {
                        Text(buttonLabel)
                            .font(Theme.Typography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(isValid ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.3))
                            .cornerRadius(Theme.CornerRadius.large)
                    }
                    .disabled(!isValid)
                    .accessibilityLabel(buttonLabel)
                    .accessibilityHint(isValid ? "Tap to save" : "Enter amount and select account first")
                    .padding(.top, Theme.Spacing.xxs)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
                .animation(.smooth, value: selectedType)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .scrollDismissesKeyboard(.immediately)

            if showingSuccess { successOverlay }
        }
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if amountFocused {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { amountFocused = false }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(viewModel: viewModel)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selectedCurrency: $viewModel.appState.selectedCurrency)
                .presentationDetents([.medium, .large])
        }
        .onChange(of: viewModel.appState.selectedCurrency) { _, _ in
            viewModel.saveData()
        }
    }
    
    // MARK: - Helpers

    /// Locale-aware amount parsing with max-value guard.
    private var parsedAmount: Double? {
        let cleaned = amount.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }

        // Try current locale's decimal separator first (handles "10,50" in European locales)
        let localeFormatter = NumberFormatter()
        localeFormatter.numberStyle = .decimal
        localeFormatter.locale = Locale.current
        if let value = localeFormatter.number(from: cleaned)?.doubleValue,
           value > 0, value <= 999_999_999 {
            return value
        }

        // Fallback: simple comma→dot swap for US-style input
        let swapped = cleaned.replacingOccurrences(of: ",", with: ".")
        if let value = Double(swapped), value > 0, value <= 999_999_999 {
            return value
        }
        return nil
    }

    private var buttonLabel: String {
        if isRecurring { return "Create Recurring" }
        guard let type = selectedType else { return "Record" }
        return "Record \(type.rawValue)"
    }

    private var isValid: Bool {
        guard parsedAmount != nil, selectedAccountId != nil, selectedType != nil else { return false }
        if selectedType == .transfer { return toAccountId != nil && toAccountId != selectedAccountId }
        return true
    }

    private func recordTransaction() {
        guard let val = parsedAmount,
              let accountId = selectedAccountId,
              let type = selectedType else { return }
        
        if isRecurring {
            let recurring = RecurringTransaction(
                title: title.isEmpty ? (viewModel.getCategory(by: selectedCategoryId)?.name ?? type.rawValue) : title,
                amount: val, type: type, accountId: accountId,
                categoryId: selectedCategoryId, frequency: recurringFrequency,
                startDate: date, endDate: hasEndDate ? recurringEndDate : nil,
                note: note, notifyDaysBefore: notifyDaysBefore
            )
            viewModel.addRecurring(recurring)
        } else {
            let tx = Transaction(
                amount: val, type: type, accountId: accountId,
                categoryId: type != .transfer ? selectedCategoryId : nil,
                toAccountId: type == .transfer ? toAccountId : nil,
                title: title, note: note, date: date
            )
            viewModel.addTransaction(tx)
        }
        
        Haptics.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showingSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.25)) { showingSuccess = false; resetForm() }
        }
    }
    
    private func resetForm() {
        amount = ""; title = ""; note = ""; date = Date()
        selectedCategoryId = nil; selectedAccountId = nil
        isRecurring = false; recurringFrequency = .monthly
        hasEndDate = false; recurringEndDate = nil
        if initialType == nil { selectedType = nil }
    }
    
    @ViewBuilder
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea().transition(.opacity)
            
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.12)).frame(width: 100, height: 100)
                    Circle().fill(Color.blue.opacity(0.18)).frame(width: 76, height: 76)
                    Image(systemName: isRecurring ? "repeat.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                        .symbolEffect(.bounce.up.byLayer, value: showingSuccess)
                }
                
                Text(isRecurring ? "Recurring Created" : "Transaction Recorded")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 20)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }
}

// MARK: - Amount Input
struct AmountInputSection: View {
    @Binding var amount: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: 8) {
            Text("Enter amount")
                .font(.system(size: 13))
                .foregroundColor(Color(uiColor: .secondaryLabel))

            HStack(spacing: 2) {
                Text("$")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(Color(uiColor: .label).opacity(amount.isEmpty ? 0.25 : 1))

                ZStack(alignment: .leading) {
                    if amount.isEmpty {
                        Text("0")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(Color(uiColor: .label).opacity(0.2))
                            .allowsHitTesting(false)
                    }

                    TextField("", text: $amount)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color(uiColor: .label))
                        .fixedSize()
                        .focused(isFocused)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .contentShape(Rectangle())
        .onTapGesture { isFocused.wrappedValue = true }
    }
}

// MARK: - Currency Row
private struct RecordCurrencyRow: View {
    let currency: String
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text("Currency")
                .font(.system(size: 15))
                .foregroundColor(Color(uiColor: .label))
            
            Spacer()
            
            Button(action: onTap) {
                HStack(spacing: 4) {
                    Text(currency)
                        .font(.system(size: 15, weight: .medium))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

// MARK: - Type Selector
private struct TypeSelectorCard: View {
    @Binding var selectedType: TransactionType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Type")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            
            HStack(spacing: 10) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    RecordTypeButton(
                        type: type,
                        isSelected: selectedType == type,
                        action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selectedType = type }
                            Haptics.selection()
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

private struct RecordTypeButton: View {
    let type: TransactionType
    let isSelected: Bool
    let action: () -> Void
    
    private var typeColor: Color {
        switch type {
        case .income: return Theme.Colors.income
        case .expense: return Theme.Colors.expense
        case .transfer: return Theme.Colors.transfer
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 22, weight: .medium))
                    .symbolEffect(.bounce.byLayer, value: isSelected)
                Text(type.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? typeColor : Color(uiColor: .secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : Color(uiColor: .secondaryLabel))
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Account Selection
private struct AccountSelectionCard: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Binding var selectedAccountId: UUID?
    @Binding var toAccountId: UUID?
    let isTransfer: Bool
    @Binding var showingAddAccount: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isTransfer ? "From Account" : "Account")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.accounts) { account in
                        RecordAccountPill(
                            account: account,
                            isSelected: selectedAccountId == account.id,
                            action: {
                                withAnimation(.snappy) { selectedAccountId = account.id }
                                Haptics.selection()
                            }
                        )
                    }
                    
                    Button(action: { showingAddAccount = true; Haptics.light() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                            Text("Add").font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Theme.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.Colors.primary.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }
            }
            
            if isTransfer {
                Text("To Account")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .padding(.top, 6)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.accounts.filter { $0.id != selectedAccountId }) { account in
                            RecordAccountPill(
                                account: account,
                                isSelected: toAccountId == account.id,
                                action: {
                                    withAnimation(.snappy) { toAccountId = account.id }
                                    Haptics.selection()
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

private struct RecordAccountPill: View {
    let account: Account
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: account.icon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : account.colorValue)
                    .frame(width: 28, height: 28)
                    .background(isSelected ? account.colorValue : account.colorValue.opacity(0.12))
                    .clipShape(Circle())
                
                Text(account.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(uiColor: .label))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? account.colorValue : Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Selection
struct CategorySelectionCard: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Binding var selectedCategoryId: UUID?
    let categoryType: CategoryType
    @Binding var showingAddCategory: Bool
    
    private var categories: [Category] {
        viewModel.categories.filter { $0.type == categoryType || $0.type == .both }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            
            if categories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 32))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                    
                    Text("No categories yet")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Button(action: { showingAddCategory = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Category")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(categories) { cat in
                        RecordCategoryTile(
                            category: cat,
                            isSelected: selectedCategoryId == cat.id,
                            action: {
                                withAnimation(.snappy) { selectedCategoryId = cat.id }
                                Haptics.selection()
                            }
                        )
                    }
                    
                    Button(action: { showingAddCategory = true; Haptics.light() }) {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    .foregroundColor(Color(uiColor: .separator))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(uiColor: .secondaryLabel))
                            }
                            
                            Text("New")
                                .font(.system(size: 11))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

private struct RecordCategoryTile: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.colorValue : category.colorValue.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .white : category.colorValue)
                        .symbolEffect(.bounce.byLayer, value: isSelected)
                }
                
                Text(category.name)
                    .font(.system(size: 11))
                    .foregroundColor(Color(uiColor: .label))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Details
private struct DetailsCard: View {
    @Binding var title: String
    @Binding var note: String
    @Binding var date: Date
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Title")
                    .font(.system(size: 15))
                    .foregroundColor(Color(uiColor: .label))
                Spacer()
                TextField("Optional", text: $title)
                    .font(.system(size: 15))
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(Color(uiColor: .label))
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
            
            Divider().padding(.leading, 16)
            
            HStack {
                Text("Note")
                    .font(.system(size: 15))
                    .foregroundColor(Color(uiColor: .label))
                Spacer()
                TextField("Optional", text: $note)
                    .font(.system(size: 15))
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
            
            Divider().padding(.leading, 16)
            
            HStack {
                Text("Date")
                    .font(.system(size: 15))
                    .foregroundColor(Color(uiColor: .label))
                Spacer()
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Recurring
private struct RecurringCard: View {
    @Binding var isRecurring: Bool
    @Binding var frequency: RecurringFrequency
    @Binding var hasEndDate: Bool
    @Binding var endDate: Date?
    @Binding var notifyDays: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "repeat.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isRecurring ? Theme.Colors.recurring : Color(uiColor: .secondaryLabel))
                    .symbolEffect(.bounce, value: isRecurring)
                
                Text("Recurring")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                Spacer()
                
                Toggle("", isOn: $isRecurring)
                    .tint(Theme.Colors.recurring)
            }
            
            if isRecurring {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Frequency")
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                Button(action: { frequency = freq; Haptics.selection() }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: freq.icon)
                                            .font(.system(size: 11))
                                        Text(freq.rawValue)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(frequency == freq ? Theme.Colors.recurring : Color(uiColor: .secondarySystemGroupedBackground))
                                    .foregroundColor(frequency == freq ? .white : Color(uiColor: .label))
                                    .cornerRadius(16)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Divider()
                
                Toggle(isOn: $hasEndDate) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        Text("Set end date")
                            .font(.system(size: 15))
                    }
                }
                .tint(Theme.Colors.recurring)
                
                if hasEndDate {
                    DatePicker(
                        "End Date",
                        selection: Binding(
                            get: { endDate ?? Date() },
                            set: { endDate = $0 }
                        ),
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    Text("Notify me")
                        .font(.system(size: 15))
                    Spacer()
                    Picker("", selection: $notifyDays) {
                        Text("Same day").tag(0)
                        Text("1 day before").tag(1)
                        Text("3 days before").tag(3)
                        Text("1 week before").tag(7)
                    }
                    .labelsHidden()
                    .tint(Color(uiColor: .secondaryLabel))
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isRecurring)
    }
}

// MARK: - Placeholder
private struct RecordPlaceholderCard: View {
    let label: String
    let hint: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
            Text(hint)
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .opacity(0.5)
    }
}

// MARK: - Add Account/Category Sheets (quick inline from Record)
struct AddAccountSheet: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        AddAccountView(viewModel: viewModel)
    }
}

struct AddCategorySheet: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    let categoryType: CategoryType
    
    var body: some View {
        AddCategoryView(viewModel: viewModel)
    }
}

// MARK: - Currency Picker Sheet
struct CurrencyPickerSheet: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    
    private let currencies = Currency.allCurrencies
    
    private var filtered: [Currency] {
        if search.isEmpty { return currencies }
        return currencies.filter {
            $0.code.localizedCaseInsensitiveContains(search) ||
            $0.name.localizedCaseInsensitiveContains(search)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered, id: \.code) { currency in
                    Button(action: {
                        selectedCurrency = currency.code
                        Haptics.selection()
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Text(currency.flag)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(currency.code)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(uiColor: .label))
                                Text(currency.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(uiColor: .secondaryLabel))
                            }
                            
                            Spacer()
                            
                            Text(currency.symbol)
                                .font(.system(size: 15))
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                            
                            if selectedCurrency == currency.code {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search currencies")
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
