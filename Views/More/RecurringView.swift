import SwiftUI

// MARK: - Recurring Transactions View with Income/Expense Filter
struct RecurringView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var showingAddRecurring = false
    @State private var selectedFilter: TransactionType? = nil
    
    private var filteredRecurring: [RecurringTransaction] {
        if let filter = selectedFilter {
            return viewModel.recurringTransactions.filter { $0.type == filter }
        }
        return viewModel.recurringTransactions
    }
    
    var body: some View {
        List {
            // Filter Section
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        FilterChip(title: "All", isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }
                        FilterChip(title: "Expenses", icon: "arrow.up.circle.fill", color: Theme.Colors.expense, isSelected: selectedFilter == .expense) {
                            selectedFilter = .expense
                        }
                        FilterChip(title: "Income", icon: "arrow.down.circle.fill", color: Theme.Colors.income, isSelected: selectedFilter == .income) {
                            selectedFilter = .income
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            // Overdue Section
            let overdue = filteredRecurring.filter { $0.isOverdue && $0.isActive }
            if !overdue.isEmpty {
                Section {
                    ForEach(overdue) { recurring in
                        RecurringRow(
                            recurring: recurring,
                            viewModel: viewModel,
                            isOverdue: true
                        )
                    }
                } header: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Theme.Colors.expense)
                        Text("Overdue")
                    }
                }
            }
            
            // Upcoming This Week
            let upcomingThisWeek = filteredRecurring.filter { $0.isActive && !$0.isOverdue && $0.daysUntilDue <= 7 }
            if !upcomingThisWeek.isEmpty {
                Section("Upcoming This Week") {
                    ForEach(upcomingThisWeek) { recurring in
                        RecurringRow(
                            recurring: recurring,
                            viewModel: viewModel,
                            isOverdue: false
                        )
                    }
                }
            }
            
            // All Active
            let activeRecurring = filteredRecurring.filter { $0.isActive && !$0.isOverdue && $0.daysUntilDue > 7 }
            if !activeRecurring.isEmpty {
                Section("All Active") {
                    ForEach(activeRecurring) { recurring in
                        RecurringRow(
                            recurring: recurring,
                            viewModel: viewModel,
                            isOverdue: false
                        )
                    }
                }
            }
            
            // Inactive
            let inactiveRecurring = filteredRecurring.filter { !$0.isActive }
            if !inactiveRecurring.isEmpty {
                Section("Inactive") {
                    ForEach(inactiveRecurring) { recurring in
                        RecurringRow(
                            recurring: recurring,
                            viewModel: viewModel,
                            isOverdue: false
                        )
                    }
                }
            }
            
            // Empty State
            if filteredRecurring.isEmpty {
                Section {
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "repeat.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Text("No Recurring Transactions")
                            .font(Theme.Typography.headline)
                        
                        Text("Add subscriptions, bills, or regular income to track them automatically")
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showingAddRecurring = true }) {
                            Text("Add Recurring")
                                .secondaryButtonStyle()
                        }
                        .frame(width: 200)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.xl)
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Recurring")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddRecurring = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRecurring) {
            AddRecurringView(viewModel: viewModel)
        }
    }
}

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    var color: Color = .gray
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            Haptics.selection()
        }) {
            HStack(spacing: Theme.Spacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(Theme.Typography.caption)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(isSelected ? color : Theme.Colors.secondaryBackground)
            .foregroundColor(isSelected ? .white : Theme.Colors.primaryText)
            .cornerRadius(Theme.CornerRadius.extraLarge)
        }
    }
}

// MARK: - Recurring Row
struct RecurringRow: View {
    let recurring: RecurringTransaction
    @ObservedObject var viewModel: BalanceViewModel
    let isOverdue: Bool
    
    @State private var showingDetail = false
    
    private var account: Account? {
        viewModel.getAccount(by: recurring.accountId)
    }
    
    private var category: Category? {
        viewModel.getCategory(by: recurring.categoryId)
    }
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(spacing: Theme.Spacing.sm) {
                // Icon with category/account color
                ZStack {
                    Circle()
                        .fill((category?.colorValue ?? account?.colorValue ?? iconColor).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: category?.icon ?? recurring.frequency.icon)
                        .font(.system(size: 18))
                        .foregroundColor(category?.colorValue ?? account?.colorValue ?? iconColor)
                }
                
                // Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(recurring.title)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    HStack(spacing: Theme.Spacing.xxs) {
                        Text(recurring.frequency.rawValue)
                        if let category = category {
                            Text("•")
                            Text(category.name)
                        }
                    }
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                // Amount and Due
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(recurring.amount, currency: viewModel.appState.selectedCurrency))
                        .font(Theme.Typography.transactionAmount)
                        .foregroundColor(recurring.type == .expense ? Theme.Colors.expense : Theme.Colors.income)
                    
                    Text(dueDateText)
                        .font(Theme.Typography.caption)
                        .foregroundColor(isOverdue ? Theme.Colors.expense : Theme.Colors.secondaryText)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            .padding(.vertical, Theme.Spacing.xxs)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            RecurringDetailView(viewModel: viewModel, recurring: recurring)
        }
    }
    
    private var iconColor: Color {
        if isOverdue { return Theme.Colors.expense }
        if recurring.type == .expense { return Theme.Colors.expense }
        return Theme.Colors.income
    }
    
    private var dueDateText: String {
        if isOverdue {
            return "Overdue"
        } else if recurring.isDueToday {
            return "Due today"
        } else if recurring.daysUntilDue == 1 {
            return "Due tomorrow"
        } else if recurring.daysUntilDue <= 7 {
            return "Due in \(recurring.daysUntilDue) days"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: recurring.nextDueDate)
        }
    }
}

// MARK: - Add Recurring View (Improved UI)
struct AddRecurringView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedAccountId: UUID?
    @State private var selectedCategoryId: UUID?
    @State private var frequency: RecurringFrequency = .monthly
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var note = ""
    @State private var notifyDaysBefore: Set<Int> = [1] // Multiple notifications
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Amount Card
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(selectedType == .expense ? "How much is this payment?" : "How much do you receive?")
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        HStack(alignment: .center, spacing: Theme.Spacing.xxs) {
                            Text(currencySymbol)
                                .font(Theme.Typography.amountInput)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            TextField("0", text: $amount)
                                .font(Theme.Typography.amountInput)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .foregroundColor(selectedType == .expense ? Theme.Colors.expense : Theme.Colors.income)
                        }
                    }
                    .padding(Theme.Spacing.xl)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.large)
                    
                    // Type Selector
                    HStack(spacing: Theme.Spacing.sm) {
                        TypeSelectionButton(
                            type: .expense,
                            isSelected: selectedType == .expense,
                            action: { selectedType = .expense }
                        )
                        TypeSelectionButton(
                            type: .income,
                            isSelected: selectedType == .income,
                            action: { selectedType = .income }
                        )
                    }
                    
                    // Title Card
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Title")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        TextField("e.g., Netflix, Rent, Salary", text: $title)
                            .font(Theme.Typography.body)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.secondaryBackground)
                            .cornerRadius(Theme.CornerRadius.small)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                    
                    // Frequency Card
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Frequency")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.primaryText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.sm) {
                                ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                    FrequencyButton(
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
                        
                        Divider()
                        
                        // Start Date
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Theme.Colors.primary)
                            Text("Start Date")
                            Spacer()
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        
                        // End Date Toggle
                        Toggle(isOn: $hasEndDate) {
                            HStack {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .foregroundColor(.orange)
                                Text("Set end date")
                            }
                        }
                        
                        if hasEndDate {
                            HStack {
                                Text("End Date")
                                Spacer()
                                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .padding(.leading, 28)
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                    
                    // Account & Category Card
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        // Account
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Account")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    ForEach(viewModel.accounts) { account in
                                        AccountChip(
                                            account: account,
                                            isSelected: selectedAccountId == account.id,
                                            action: { selectedAccountId = account.id }
                                        )
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Category
                        let categories = selectedType == .expense ? viewModel.expenseCategories : viewModel.incomeCategories
                        if !categories.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Category")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Theme.Spacing.sm) {
                                    ForEach(categories) { category in
                                        CategoryChip(
                                            category: category,
                                            isSelected: selectedCategoryId == category.id,
                                            action: { selectedCategoryId = category.id }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                    
                    // Notifications Card (Multiple selection)
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("Notifications")
                                .font(Theme.Typography.headline)
                        }
                        
                        Text("Select when you want to be reminded")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Theme.Spacing.sm) {
                            NotificationToggle(label: "Same day", value: 0, selected: $notifyDaysBefore)
                            NotificationToggle(label: "1 day before", value: 1, selected: $notifyDaysBefore)
                            NotificationToggle(label: "3 days before", value: 3, selected: $notifyDaysBefore)
                            NotificationToggle(label: "1 week before", value: 7, selected: $notifyDaysBefore)
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                    
                    // Note
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Note (optional)")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        TextField("Add any extra details...", text: $note)
                            .font(Theme.Typography.body)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.secondaryBackground)
                            .cornerRadius(Theme.CornerRadius.small)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                    
                    // Add Button
                    Button(action: addRecurring) {
                        HStack {
                            Image(systemName: "repeat")
                            Text("Create Recurring")
                        }
                        .primaryButtonStyle()
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.5)
                    .padding(.top, Theme.Spacing.sm)
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("New Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                selectedAccountId = viewModel.accounts.first?.id
            }
        }
    }
    
    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.appState.selectedCurrency
        return formatter.currencySymbol ?? "$"
    }
    
    private var isValid: Bool {
        !title.isEmpty &&
        Double(amount.replacingOccurrences(of: ",", with: ".")) != nil &&
        selectedAccountId != nil
    }
    
    private func addRecurring() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")),
              let accountId = selectedAccountId else { return }
        
        // Use the first selected notification day
        let notifyDay = notifyDaysBefore.min() ?? 1
        
        let recurring = RecurringTransaction(
            title: title,
            amount: amountValue,
            type: selectedType,
            accountId: accountId,
            categoryId: selectedCategoryId,
            frequency: frequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            note: note,
            notifyDaysBefore: notifyDay
        )
        
        viewModel.addRecurring(recurring)
        Haptics.success()
        dismiss()
    }
}

struct TypeSelectionButton: View {
    let type: TransactionType
    let isSelected: Bool
    let action: () -> Void
    
    private var color: Color {
        type == .expense ? Theme.Colors.expense : Theme.Colors.income
    }
    
    var body: some View {
        Button(action: {
            action()
            Haptics.selection()
        }) {
            VStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: type == .expense ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.title2)
                Text(type.rawValue)
                    .font(Theme.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(isSelected ? color : Theme.Colors.cardBackground)
            .foregroundColor(isSelected ? .white : Theme.Colors.secondaryText)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }
}

struct FrequencyButton: View {
    let frequency: RecurringFrequency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: frequency.icon)
                    .font(.system(size: 20))
                Text(frequency.rawValue)
                    .font(Theme.Typography.caption)
            }
            .frame(width: 70)
            .padding(.vertical, Theme.Spacing.sm)
            .background(isSelected ? Color.purple : Theme.Colors.secondaryBackground)
            .foregroundColor(isSelected ? .white : Theme.Colors.primaryText)
            .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

struct AccountChip: View {
    let account: Account
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            Haptics.selection()
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: account.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : account.colorValue)
                Text(account.name)
                    .font(Theme.Typography.caption)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
            .foregroundColor(isSelected ? .white : Theme.Colors.primaryText)
            .cornerRadius(Theme.CornerRadius.extraLarge)
        }
    }
}

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            Haptics.selection()
        }) {
            VStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : category.colorValue)
                Text(category.name)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xs)
            .background(isSelected ? category.colorValue : Theme.Colors.secondaryBackground)
            .foregroundColor(isSelected ? .white : Theme.Colors.primaryText)
            .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

struct NotificationToggle: View {
    let label: String
    let value: Int
    @Binding var selected: Set<Int>
    
    var isSelected: Bool {
        selected.contains(value)
    }
    
    var body: some View {
        Button(action: {
            if isSelected {
                selected.remove(value)
            } else {
                selected.insert(value)
            }
            Haptics.selection()
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .orange : Theme.Colors.secondaryText)
                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.primaryText)
            }
            .padding(Theme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.orange.opacity(0.1) : Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

// MARK: - Recurring Detail View
struct RecurringDetailView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let recurring: RecurringTransaction
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEdit = false
    
    private var account: Account? {
        viewModel.getAccount(by: recurring.accountId)
    }
    
    private var category: Category? {
        viewModel.getCategory(by: recurring.categoryId)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Header
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: Theme.Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill((category?.colorValue ?? (recurring.type == .expense ? Theme.Colors.expense : Theme.Colors.income)).opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: category?.icon ?? recurring.frequency.icon)
                                    .font(.system(size: 36))
                                    .foregroundColor(category?.colorValue ?? (recurring.type == .expense ? Theme.Colors.expense : Theme.Colors.income))
                            }
                            
                            Text(recurring.title)
                                .font(Theme.Typography.title2)
                            
                            Text(formatCurrency(recurring.amount, currency: viewModel.appState.selectedCurrency))
                                .font(Theme.Typography.balanceAmount)
                                .foregroundColor(recurring.type == .expense ? Theme.Colors.expense : Theme.Colors.income)
                            
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: recurring.frequency.icon)
                                Text(recurring.frequency.rawValue)
                            }
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                // Schedule - Shows Start Date AND Next Due
                Section("Schedule") {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(Theme.Colors.primary)
                        Text("Started")
                        Spacer()
                        Text(formatDate(recurring.startDate))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(recurring.isOverdue ? Theme.Colors.expense : Theme.Colors.primary)
                        Text("Next Due")
                        Spacer()
                        if recurring.isOverdue {
                            Text("Overdue")
                                .foregroundColor(Theme.Colors.expense)
                                .fontWeight(.semibold)
                        } else if recurring.isDueToday {
                            Text("Today")
                                .foregroundColor(Theme.Colors.primary)
                                .fontWeight(.semibold)
                        } else {
                            Text(formatDate(recurring.nextDueDate))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    
                    if let lastProcessed = recurring.lastProcessedDate {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.Colors.income)
                            Text("Last Processed")
                            Spacer()
                            Text(formatDate(lastProcessed))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    
                    if let endDate = recurring.endDate {
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .foregroundColor(.orange)
                            Text("End Date")
                            Spacer()
                            Text(formatDate(endDate))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                
                // Details
                Section("Details") {
                    HStack {
                        Text("Type")
                        Spacer()
                        HStack(spacing: Theme.Spacing.xxs) {
                            Image(systemName: recurring.type == .expense ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(recurring.type == .expense ? Theme.Colors.expense : Theme.Colors.income)
                            Text(recurring.type.rawValue)
                        }
                        .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    if let account = account {
                        HStack {
                            Text("Account")
                            Spacer()
                            HStack {
                                Image(systemName: account.icon)
                                    .foregroundColor(account.colorValue)
                                Text(account.name)
                            }
                            .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    
                    if let category = category {
                        HStack {
                            Text("Category")
                            Spacer()
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.colorValue)
                                Text(category.name)
                            }
                            .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    
                    if !recurring.note.isEmpty {
                        HStack(alignment: .top) {
                            Text("Note")
                            Spacer()
                            Text(recurring.note)
                                .foregroundColor(Theme.Colors.secondaryText)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                // Actions
                Section {
                    if recurring.isActive && (recurring.isDueToday || recurring.isOverdue) {
                        Button(action: {
                            viewModel.processRecurring(recurring)
                            Haptics.success()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Record & Move to Next")
                            }
                            .foregroundColor(Theme.Colors.income)
                        }
                    }
                    
                    Button(action: {
                        var updated = recurring
                        updated.isActive.toggle()
                        viewModel.updateRecurring(updated)
                    }) {
                        HStack {
                            Image(systemName: recurring.isActive ? "pause.circle.fill" : "play.circle.fill")
                            Text(recurring.isActive ? "Pause" : "Resume")
                        }
                        .foregroundColor(recurring.isActive ? .orange : Theme.Colors.income)
                    }
                    
                    Button(role: .destructive, action: {
                        viewModel.deleteRecurring(recurring)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete")
                        }
                    }
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") { showingEdit = true }
                }
            }
            .sheet(isPresented: $showingEdit) {
                EditRecurringView(viewModel: viewModel, recurring: recurring)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Edit Recurring View
struct EditRecurringView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let recurring: RecurringTransaction
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var amount: String
    @State private var selectedType: TransactionType
    @State private var selectedAccountId: UUID?
    @State private var selectedCategoryId: UUID?
    @State private var frequency: RecurringFrequency
    @State private var nextDueDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var note: String
    @State private var notifyDaysBefore: Int
    
    init(viewModel: BalanceViewModel, recurring: RecurringTransaction) {
        self.viewModel = viewModel
        self.recurring = recurring
        
        _title = State(initialValue: recurring.title)
        _amount = State(initialValue: String(format: "%.2f", recurring.amount))
        _selectedType = State(initialValue: recurring.type)
        _selectedAccountId = State(initialValue: recurring.accountId)
        _selectedCategoryId = State(initialValue: recurring.categoryId)
        _frequency = State(initialValue: recurring.frequency)
        _nextDueDate = State(initialValue: recurring.nextDueDate)
        _hasEndDate = State(initialValue: recurring.endDate != nil)
        _endDate = State(initialValue: recurring.endDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date())
        _note = State(initialValue: recurring.note)
        _notifyDaysBefore = State(initialValue: recurring.notifyDaysBefore)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    
                    HStack {
                        Text(currencySymbol)
                            .foregroundColor(Theme.Colors.secondaryText)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Type", selection: $selectedType) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Frequency") {
                    Picker("Repeat", selection: $frequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    DatePicker("Next Due Date", selection: $nextDueDate, displayedComponents: .date)
                    
                    Toggle("Has End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, in: nextDueDate..., displayedComponents: .date)
                    }
                }
                
                Section("Account & Category") {
                    Picker("Account", selection: $selectedAccountId) {
                        ForEach(viewModel.accounts) { account in
                            Text(account.name).tag(account.id as UUID?)
                        }
                    }
                    
                    let categories = selectedType == .expense ? viewModel.expenseCategories : viewModel.incomeCategories
                    if !categories.isEmpty {
                        Picker("Category", selection: $selectedCategoryId) {
                            Text("None").tag(nil as UUID?)
                            ForEach(categories) { category in
                                Text(category.name).tag(category.id as UUID?)
                            }
                        }
                    }
                }
                
                Section("Notifications") {
                    Picker("Remind me", selection: $notifyDaysBefore) {
                        Text("Same day").tag(0)
                        Text("1 day before").tag(1)
                        Text("2 days before").tag(2)
                        Text("3 days before").tag(3)
                        Text("1 week before").tag(7)
                    }
                }
                
                Section("Note") {
                    TextField("Note (optional)", text: $note)
                }
            }
            .navigationTitle("Edit Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.appState.selectedCurrency
        return formatter.currencySymbol ?? "$"
    }
    
    private func saveChanges() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")),
              let accountId = selectedAccountId else { return }
        
        var updated = recurring
        updated.title = title
        updated.amount = amountValue
        updated.type = selectedType
        updated.accountId = accountId
        updated.categoryId = selectedCategoryId
        updated.frequency = frequency
        updated.nextDueDate = nextDueDate
        updated.endDate = hasEndDate ? endDate : nil
        updated.note = note
        updated.notifyDaysBefore = notifyDaysBefore
        
        viewModel.updateRecurring(updated)
        Haptics.success()
        dismiss()
    }
}
