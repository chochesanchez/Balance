import SwiftUI

// MARK: - Record View v2
/// Redesigned transaction entry with type-colored backgrounds, symbol effects, and improved success overlay
struct RecordView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    var initialType: TransactionType?
    
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
    
    // Recurring options
    @State private var isRecurring = false
    @State private var showRecurringOptions = false
    @State private var recurringFrequency: RecurringFrequency = .monthly
    @State private var recurringEndDate: Date? = nil
    @State private var hasEndDate = false
    @State private var notifyDaysBefore = 1
    
    // Currency picker
    @State private var showCurrencyPicker = false
    
    // Scroll tracking
    @State private var showStickyHeader = false
    
    init(viewModel: BalanceViewModel, initialType: TransactionType? = nil) {
        self.viewModel = viewModel
        self.initialType = initialType
        _selectedType = State(initialValue: initialType)
    }
    
    // MARK: - Type-based background color
    private var typeBackgroundColor: Color {
        guard let type = selectedType else { return Theme.Colors.cardBackground }
        switch type {
        case .income: return Theme.Colors.income.opacity(0.06)
        case .expense: return Theme.Colors.expense.opacity(0.06)
        case .transfer: return Theme.Colors.transfer.opacity(0.06)
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Widget 1: Amount
                    AmountInputSection(
                        amount: $amount,
                        transactionType: selectedType,
                        currency: viewModel.appState.selectedCurrency,
                        onCurrencyTap: { showCurrencyPicker = true }
                    )
                    
                    // Widget 2: Type
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Type")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        
                        TypeSelectorSection(selectedType: $selectedType)
                    }
                    .padding(16)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(16)
                    
                    // Widget 3: Account
                    AccountSelectionSection(
                        viewModel: viewModel,
                        selectedAccountId: $selectedAccountId,
                        toAccountId: $toAccountId,
                        isTransfer: selectedType == .transfer,
                        showingAddAccount: $showingAddAccount
                    )
                    
                    // Widget 4: Category
                    if selectedType != nil && selectedType != .transfer {
                        CategorySelectionSection(
                            viewModel: viewModel,
                            selectedCategoryId: $selectedCategoryId,
                            categoryType: selectedType == .income ? .income : .expense,
                            showingAddCategory: $showingAddCategory,
                            isTransfer: false
                        )
                        .transition(.asymmetric(
                            insertion: .push(from: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    } else if selectedType == nil {
                        CategoryPlaceholder()
                    }
                    
                    // Widget 5: Details (title, note, date)
                    DetailsSection(title: $title, note: $note, date: $date)
                    
                    // Widget 6: Recurring
                    if selectedType == .income || selectedType == .expense {
                        RecurringToggleSection(
                            isRecurring: $isRecurring,
                            frequency: $recurringFrequency,
                            hasEndDate: $hasEndDate,
                            endDate: $recurringEndDate,
                            notifyDays: $notifyDaysBefore
                        )
                        .transition(.push(from: .bottom).combined(with: .opacity))
                    }
                    
                    // Record Button
                    Button(action: recordTransaction) {
                        Text(buttonText)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(isValidTransaction ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.35))
                            .cornerRadius(14)
                    }
                    .buttonStyle(PressEffectButtonStyle())
                    .disabled(!isValidTransaction)
                    .animation(.smooth, value: isValidTransaction)
                    
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .animation(.smooth, value: selectedType)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            
            if showingSuccess {
                successOverlay
            }
        }
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddAccount) {
            AddAccountSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet(viewModel: viewModel, categoryType: selectedType == .income ? .income : .expense)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(
                selectedCurrency: Binding(
                    get: { viewModel.appState.selectedCurrency },
                    set: { viewModel.appState.selectedCurrency = $0 }
                )
            )
        }
    }
    
    private var buttonText: String {
        if isRecurring { return "Create Recurring" }
        guard let type = selectedType else { return "Record" }
        return "Record \(type.rawValue)"
    }
    
    private var isValidTransaction: Bool {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")),
              amountValue > 0,
              selectedAccountId != nil,
              selectedType != nil else { return false }
        
        if selectedType == .transfer {
            return toAccountId != nil && toAccountId != selectedAccountId
        }
        return true
    }
    
    private func recordTransaction() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")),
              let accountId = selectedAccountId,
              let type = selectedType else { return }
        
        if isRecurring {
            let recurring = RecurringTransaction(
                title: title.isEmpty ? (viewModel.getCategory(by: selectedCategoryId)?.name ?? type.rawValue) : title,
                amount: amountValue,
                type: type,
                accountId: accountId,
                categoryId: selectedCategoryId,
                frequency: recurringFrequency,
                startDate: date,
                endDate: hasEndDate ? recurringEndDate : nil,
                note: note,
                notifyDaysBefore: notifyDaysBefore
            )
            viewModel.addRecurring(recurring)
        } else {
            let transaction = Transaction(
                amount: amountValue,
                type: type,
                accountId: accountId,
                categoryId: type != .transfer ? selectedCategoryId : nil,
                toAccountId: type == .transfer ? toAccountId : nil,
                title: title,
                note: note,
                date: date
            )
            viewModel.addTransaction(transaction)
        }
        
        withAnimation(Theme.Animation.bouncy) {
            showingSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(Theme.Animation.smooth) {
                showingSuccess = false
                resetForm()
            }
        }
    }
    
    private func resetForm() {
        amount = ""
        title = ""
        note = ""
        date = Date()
        selectedCategoryId = nil
        selectedAccountId = nil
        isRecurring = false
        recurringFrequency = .monthly
        hasEndDate = false
        recurringEndDate = nil
        if initialType == nil {
            selectedType = nil
        }
    }
    
    // MARK: - Success Overlay
    @ViewBuilder
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .transition(.opacity)
            
            VStack(spacing: Theme.Spacing.lg) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(Theme.Colors.income.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(Theme.Colors.income.opacity(0.2))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: isRecurring ? "repeat.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.Colors.income)
                        .symbolEffect(.bounce.up.byLayer, value: showingSuccess)
                }
                
                VStack(spacing: Theme.Spacing.xs) {
                    Text(isRecurring ? "Recurring Created" : "Transaction Recorded")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.primaryText)
                    
                    if let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) {
                        Text(formatCurrency(amountValue, currency: viewModel.appState.selectedCurrency))
                            .font(Theme.Typography.balanceAmount)
                            .foregroundStyle(Theme.Colors.income)
                            .contentTransition(.numericText())
                    }
                }
            }
            .padding(Theme.Spacing.xxl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.extraLarge, style: .continuous))
            .shadow(radius: 20)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }
}

// MARK: - Amount Input Section
struct AmountInputSection: View {
    @Binding var amount: String
    let transactionType: TransactionType?
    let currency: String
    var onCurrencyTap: (() -> Void)? = nil
    
    private var currencyCode: String { currency }
    
    private var promptText: String {
        guard let type = transactionType else { return "Enter amount" }
        switch type {
        case .expense: return "How much did you spend?"
        case .income: return "How much did you earn?"
        case .transfer: return "Transfer amount"
        }
    }
    
    private var amountColor: Color {
        guard let type = transactionType else { return Color(uiColor: .label) }
        switch type {
        case .income: return Theme.Colors.income
        case .expense: return Theme.Colors.expense
        case .transfer: return Theme.Colors.transfer
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(promptText)
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .contentTransition(.interpolate)
                .animation(.smooth, value: transactionType)
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0", text: $amount)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .foregroundColor(amountColor)
                    .animation(.smooth, value: transactionType)
                
                Button(action: { onCurrencyTap?() }) {
                    Text(currencyCode)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .cornerRadius(6)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Type Selector Section
struct TypeSelectorSection: View {
    @Binding var selectedType: TransactionType?
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                TypeButton(
                    type: type,
                    isSelected: selectedType == type,
                    action: {
                        withAnimation(Theme.Animation.bouncy) {
                            selectedType = type
                        }
                        Haptics.selection()
                    }
                )
            }
        }
    }
}

struct TypeButton: View {
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
            VStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: type.icon)
                    .font(.system(size: 22, weight: .medium))
                    .symbolEffect(.bounce.byLayer, value: isSelected)
                Text(type.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(isSelected ? typeColor : Theme.Colors.cardBackground)
            .foregroundStyle(isSelected ? .white : Theme.Colors.secondaryText)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

// MARK: - Category Placeholder
struct CategoryPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Category")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.tertiaryText)
            
            Text("Select a transaction type first")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
        .opacity(0.5)
    }
}

// MARK: - Account Selection Section
struct AccountSelectionSection: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Binding var selectedAccountId: UUID?
    @Binding var toAccountId: UUID?
    let isTransfer: Bool
    @Binding var showingAddAccount: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(isTransfer ? "From" : "Account")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.accounts) { account in
                        AccountPillWithColor(
                            account: account,
                            isSelected: selectedAccountId == account.id,
                            action: {
                                withAnimation(Theme.Animation.snappy) {
                                    selectedAccountId = account.id
                                }
                                Haptics.selection()
                            }
                        )
                    }
                    
                    AddButtonPill(action: { showingAddAccount = true })
                }
            }
            
            if isTransfer {
                Text("To")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .padding(.top, Theme.Spacing.sm)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(viewModel.accounts.filter { $0.id != selectedAccountId }) { account in
                            AccountPillWithColor(
                                account: account,
                                isSelected: toAccountId == account.id,
                                action: {
                                    withAnimation(Theme.Animation.snappy) {
                                        toAccountId = account.id
                                    }
                                    Haptics.selection()
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
    }
}

struct AccountPillWithColor: View {
    let account: Account
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(account.colorValue.opacity(0.15))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: account.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? .white : account.colorValue)
                }
                
                Text(account.name)
                    .font(Theme.Typography.subheadline)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
            .foregroundStyle(isSelected ? .white : Theme.Colors.primaryText)
            .clipShape(Capsule())
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

struct AddButtonPill: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            Haptics.light()
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                Text("Add")
                    .font(Theme.Typography.subheadline)
            }
            .foregroundStyle(Theme.Colors.primary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.Colors.primary.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

// MARK: - Recurring Toggle Section
struct RecurringToggleSection: View {
    @Binding var isRecurring: Bool
    @Binding var frequency: RecurringFrequency
    @Binding var hasEndDate: Bool
    @Binding var endDate: Date?
    @Binding var notifyDays: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "repeat.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(isRecurring ? .purple : Theme.Colors.secondaryText)
                    .symbolEffect(.bounce, value: isRecurring)
                
                Text("Recurring")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)
                
                Spacer()
                
                Toggle("", isOn: $isRecurring)
                    .tint(.purple)
            }
            
            if isRecurring {
                Divider()
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Frequency")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                FrequencyPill(
                                    frequency: freq,
                                    isSelected: frequency == freq,
                                    action: {
                                        frequency = freq
                                        Haptics.selection()
                                    }
                                )
                            }
                        }
                    }
                }
                
                Divider()
                
                Toggle(isOn: $hasEndDate) {
                    HStack {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundStyle(Theme.Colors.secondaryText)
                        Text("Set end date")
                            .font(Theme.Typography.body)
                    }
                }
                .tint(.purple)
                
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
                    Image(systemName: Theme.Icons.notification)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    
                    Text("Notify me")
                        .font(Theme.Typography.body)
                    
                    Spacer()
                    
                    Picker("", selection: $notifyDays) {
                        Text("Same day").tag(0)
                        Text("1 day before").tag(1)
                        Text("3 days before").tag(3)
                        Text("1 week before").tag(7)
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
        .animation(Theme.Animation.bouncy, value: isRecurring)
    }
}

struct FrequencyPill: View {
    let frequency: RecurringFrequency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: frequency.icon)
                    .font(.system(size: 12))
                Text(frequency.rawValue)
                    .font(Theme.Typography.caption)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(isSelected ? Color.purple : Theme.Colors.secondaryBackground)
            .foregroundStyle(isSelected ? .white : Theme.Colors.primaryText)
            .clipShape(Capsule())
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

// MARK: - Category Selection Section
struct CategorySelectionSection: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Binding var selectedCategoryId: UUID?
    let categoryType: CategoryType
    @Binding var showingAddCategory: Bool
    var isTransfer: Bool = false
    
    private var categories: [Category] {
        viewModel.categories.filter { $0.type == categoryType }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Category")
                .font(Theme.Typography.headline)
                .foregroundStyle(isTransfer ? Theme.Colors.tertiaryText : Theme.Colors.primaryText)
            
            if isTransfer {
                Text("Not applicable for transfers")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            } else if categories.isEmpty {
                // Improved empty state
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.Colors.secondaryText)
                        .symbolEffect(.pulse.byLayer)
                    
                    Text("No categories yet")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    
                    Button(action: { showingAddCategory = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Category")
                        }
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.primary)
                    }
                    .buttonStyle(PressEffectButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Theme.Spacing.sm) {
                    ForEach(categories) { category in
                        CategoryGridItem(
                            category: category,
                            isSelected: selectedCategoryId == category.id,
                            action: {
                                withAnimation(Theme.Animation.snappy) {
                                    selectedCategoryId = category.id
                                }
                                Haptics.selection()
                            }
                        )
                    }
                    
                    CategoryAddTile(action: { showingAddCategory = true })
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
        .opacity(isTransfer ? 0.5 : 1)
    }
}

struct CategoryGridItem: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xxs) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.colorValue : category.colorValue.opacity(0.15))
                        .frame(width: Theme.Sizes.iconXL, height: Theme.Sizes.iconXL)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : category.colorValue)
                        .symbolEffect(.bounce.byLayer, value: isSelected)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? category.colorValue : Color.clear, lineWidth: 2)
                        .scaleEffect(1.15)
                        .animation(Theme.Animation.bouncy, value: isSelected)
                )
                
                Text(category.name)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

struct CategoryAddTile: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            Haptics.light()
        }) {
            VStack(spacing: Theme.Spacing.xxs) {
                ZStack {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                        .foregroundStyle(Theme.Colors.border)
                        .frame(width: Theme.Sizes.iconXL, height: Theme.Sizes.iconXL)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                
                Text("New")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

// MARK: - Details Section
struct DetailsSection: View {
    @Binding var title: String
    @Binding var note: String
    @Binding var date: Date
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Title (optional)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                
                TextField("e.g., Lunch at cafe", text: $title)
                    .font(Theme.Typography.body)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small, style: .continuous))
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Note (optional)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                
                TextField("Add any extra details...", text: $note)
                    .font(Theme.Typography.body)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small, style: .continuous))
            }
            
            HStack {
                Text("Date")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.primaryText)
                
                Spacer()
                
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
    }
}

// MARK: - Add Account Sheet
struct AddAccountSheet: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedType: AccountType = .checking
    @State private var initialBalance = ""
    @State private var selectedColor = Theme.Colors.categoryColors[0]
    @State private var selectedIcon = "building.columns.fill"
    
    private let icons = [
        "building.columns.fill", "dollarsign.circle.fill", "creditcard.fill",
        "banknote.fill", "chart.line.uptrend.xyaxis", "wallet.pass.fill",
        "bitcoinsign.circle.fill", "eurosign.circle.fill", "sterlingsign.circle.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account name", text: $name)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextField("Initial balance", text: $initialBalance)
                        .keyboardType(.decimalPad)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Theme.Spacing.md) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? .white : selectedColor)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? selectedColor : selectedColor.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small, style: .continuous))
                            }
                        }
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Theme.Spacing.md) {
                        ForEach(Theme.Colors.categoryColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let account = Account(
                            name: name,
                            type: selectedType,
                            icon: selectedIcon,
                            color: selectedColor.toHex() ?? "#007AFF",
                            initialBalance: Double(initialBalance) ?? 0
                        )
                        viewModel.addAccount(account)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Add Category Sheet
struct AddCategorySheet: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    let categoryType: CategoryType
    
    @State private var name = ""
    @State private var selectedColor = Theme.Colors.categoryColors[0]
    @State private var selectedIcon = "tag.fill"
    @State private var budget = ""
    
    private let icons = [
        "fork.knife", "car.fill", "house.fill", "bag.fill", "heart.fill",
        "gamecontroller.fill", "book.fill", "music.note", "film.fill",
        "airplane", "gift.fill", "cart.fill", "creditcard.fill", "briefcase.fill",
        "graduationcap.fill", "cross.fill", "pawprint.fill", "figure.run",
        "tshirt.fill", "scissors", "wrench.fill", "phone.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Category name", text: $name)
                    
                    if categoryType == .expense {
                        TextField("Monthly budget (optional)", text: $budget)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Theme.Spacing.md) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? .white : selectedColor)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? selectedColor : selectedColor.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small, style: .continuous))
                            }
                        }
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Theme.Spacing.md) {
                        ForEach(Theme.Colors.categoryColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let category = Category(
                            name: name,
                            icon: selectedIcon,
                            color: selectedColor.toHex() ?? "#007AFF",
                            type: categoryType,
                            budget: Double(budget)
                        )
                        viewModel.addCategory(category)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
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
