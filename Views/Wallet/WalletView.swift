import SwiftUI

// MARK: - Wallet View
/// Displays Accounts and Categories with search icon (not bar) next to + icon
struct WalletView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var selectedSegment = 0
    @State private var showingAddAccount = false
    @State private var showingAddCategory = false
    @State private var showingSearch = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar (only when active)
            if showingSearch {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    TextField("Search \(selectedSegment == 0 ? "accounts" : "categories")...", text: $searchText)
                        .font(Theme.Typography.body)
                    
                    Button(action: {
                        searchText = ""
                        showingSearch = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.medium)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)
            }
            
            // Segment Control
            Picker("View", selection: $selectedSegment) {
                Text("Accounts").tag(0)
                Text("Categories").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .onChange(of: selectedSegment) { oldValue, newValue in
                searchText = ""
            }
            
            // Content
            if selectedSegment == 0 {
                AccountsListView(viewModel: viewModel, searchText: searchText, showingAddAccount: $showingAddAccount)
            } else {
                CategoriesListView(viewModel: viewModel, searchText: searchText, showingAddCategory: $showingAddCategory)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Wallet")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    // Search Icon
                    Button(action: {
                        showingSearch.toggle()
                        if !showingSearch { searchText = "" }
                        Haptics.light()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(showingSearch ? Theme.Colors.primary : Theme.Colors.primaryText)
                    }
                    
                    // Add Icon
                    Button(action: {
                        if selectedSegment == 0 {
                            showingAddAccount = true
                        } else {
                            showingAddCategory = true
                        }
                        Haptics.light()
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(viewModel: viewModel)
        }
    }
}

// MARK: - Accounts List View
struct AccountsListView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let searchText: String
    @Binding var showingAddAccount: Bool
    
    private var filteredAccounts: [Account] {
        if searchText.isEmpty {
            return viewModel.accounts
        }
        return viewModel.accounts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                // Total Balance Card
                TotalBalanceCard(balance: viewModel.totalBalance, currency: viewModel.appState.selectedCurrency)
                    .padding(.horizontal, Theme.Spacing.md)
                
                // Accounts Section
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("My Accounts")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                        .padding(.horizontal, Theme.Spacing.md)
                    
                    if filteredAccounts.isEmpty {
                        EmptyStateView(
                            icon: "wallet.pass.fill",
                            title: "No accounts found",
                            message: searchText.isEmpty ? "Add your first account to get started" : "Try a different search"
                        )
                        .padding(.horizontal, Theme.Spacing.md)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(filteredAccounts) { account in
                                NavigationLink(destination: AccountDetailView(viewModel: viewModel, account: account)) {
                                    AccountRowView(
                                        account: account,
                                        balance: viewModel.balanceForAccount(account),
                                        currency: viewModel.appState.selectedCurrency
                                    )
                                }
                                
                                if account.id != filteredAccounts.last?.id {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(14)
                .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Total Balance Card
struct TotalBalanceCard: View {
    let balance: Double
    let currency: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Total Balance")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            
            Text(formatCurrency(balance, currency: currency))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(Color(uiColor: .label))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Account Row View (Balance always black, original icon color)
struct AccountRowView: View {
    let account: Account
    let balance: Double
    let currency: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Icon with USER'S CHOSEN COLOR (original color, not grey)
            ZStack {
                Circle()
                    .fill(account.colorValue.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: account.icon)
                    .font(.system(size: 18))
                    .foregroundColor(account.colorValue)
            }
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                HStack(spacing: Theme.Spacing.xxs) {
                    Text(account.type.rawValue)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    // Show note if exists
                    if let note = account.note, !note.isEmpty {
                        Text("•")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.tertiaryText)
                        Text(note)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.tertiaryText)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Balance - ALWAYS BLACK (green only for income transactions, not account balance)
            Text(formatCurrency(balance, currency: currency))
                .font(Theme.Typography.transactionAmount)
                .foregroundColor(Theme.Colors.primaryText)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .padding(Theme.Spacing.sm)
    }
}

// MARK: - Categories List View
struct CategoriesListView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let searchText: String
    @Binding var showingAddCategory: Bool
    
    private var filteredExpenseCategories: [Category] {
        let categories = viewModel.expenseCategories
        if searchText.isEmpty { return categories }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredIncomeCategories: [Category] {
        let categories = viewModel.incomeCategories
        if searchText.isEmpty { return categories }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var hasAnyCategories: Bool {
        !viewModel.categories.isEmpty
    }
    
    var body: some View {
        ScrollView {
            if !hasAnyCategories {
                // Clean empty state -- no section headers
                VStack(spacing: 16) {
                    Spacer().frame(height: 60)
                    
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 44))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                    
                    Text("No Categories Yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text("Create categories to organize\nyour transactions")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showingAddCategory = true }) {
                        Text("Add Category")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 180, height: 46)
                            .background(Theme.Colors.primary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PressEffectButtonStyle())
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 20) {
                    // Expense Categories
                    if !filteredExpenseCategories.isEmpty {
                        CategorySection(
                            title: "Expense",
                            categories: filteredExpenseCategories,
                            viewModel: viewModel
                        )
                    }
                    
                    // Income Categories
                    if !filteredIncomeCategories.isEmpty {
                        CategorySection(
                            title: "Income",
                            categories: filteredIncomeCategories,
                            viewModel: viewModel
                        )
                    }
                    
                    // If searching and no results
                    if filteredExpenseCategories.isEmpty && filteredIncomeCategories.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                            Text("No categories found")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding(.vertical, 16)
            }
        }
    }
}

struct CategorySection: View {
    let title: String
    let categories: [Category]
    @ObservedObject var viewModel: BalanceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .textCase(.uppercase)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    NavigationLink(destination: CategoryMetricsView(viewModel: viewModel, category: category)) {
                        CategoryRowView(category: category)
                    }
                    
                    if index < categories.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(14)
            .padding(.horizontal, 16)
        }
    }
}

struct CategoryRowView: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundColor(category.colorValue)
                .frame(width: 36, height: 36)
                .background(category.colorValue.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 1) {
                Text(category.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(uiColor: .label))
                
                if let note = category.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(uiColor: .quaternaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Category Metrics View
struct CategoryMetricsView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let category: Category
    @State private var selectedTimeRange: TimeRange = .monthly
    
    // MARK: - Computed Properties
    private var stats: CategoryStat {
        viewModel.categoryStats(for: category, in: selectedTimeRange)
    }
    
    private var monthlyAverage: Double {
        viewModel.monthlyAverage(for: category)
    }
    
    private var budgetStatus: BudgetStatus? {
        viewModel.budgetStatus(for: category)
    }
    
    private var periodTransactions: [Transaction] {
        viewModel.transactions(in: selectedTimeRange)
            .filter { $0.categoryId == category.id }
            .sorted { $0.date > $1.date }
    }
    
    private var lastTransaction: Transaction? {
        viewModel.transactionsForCategory(category).first
    }
    
    var body: some View {
        List {
            // Header
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: Theme.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(category.colorValue.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: category.icon)
                                .font(.system(size: 36))
                                .foregroundColor(category.colorValue)
                        }
                        
                        Text(category.name)
                            .font(Theme.Typography.title2)
                        
                        Text(category.type.rawValue)
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        if let note = category.note, !note.isEmpty {
                            Text(note)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.tertiaryText)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
            // Time Range Selector
            Section {
                VStack(spacing: Theme.Spacing.sm) {
                    TimeScopeSelector(selected: $selectedTimeRange, showAllOptions: false)
                    
                    // Total for period with delta
                    VStack(spacing: Theme.Spacing.xxs) {
                        Text("Total \(selectedTimeRange.shortTitle)")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Text(formatCurrency(stats.total, currency: viewModel.appState.selectedCurrency))
                            .font(Theme.Typography.balanceAmount)
                            .foregroundColor(category.colorValue)
                        
                        // Delta indicator
                        if let delta = stats.deltaFromPrevious, abs(delta) > 0.01 {
                            HStack(spacing: Theme.Spacing.xxs) {
                                Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("\(Int(abs(delta * 100)))% vs last \(selectedTimeRange.shortTitle.lowercased())")
                                    .font(Theme.Typography.caption)
                            }
                            .foregroundColor(category.type == .expense ? (delta >= 0 ? Theme.Colors.expense : Theme.Colors.income) : (delta >= 0 ? Theme.Colors.income : Theme.Colors.expense))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
                }
                .listRowBackground(Color.clear)
            }
            
            // Budget Status (if has budget)
            if let status = budgetStatus, category.budget != nil {
                Section("Budget") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            Text("Status")
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            Spacer()
                            
                            HStack(spacing: Theme.Spacing.xxs) {
                                Image(systemName: status.icon)
                                    .font(.system(size: 12))
                                Text(status.label)
                                    .font(Theme.Typography.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(status.color)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xxs)
                            .background(status.color.opacity(0.15))
                            .cornerRadius(Theme.CornerRadius.small)
                        }
                        
                        // Progress bar
                        let budget = category.budget ?? 0
                        let spent = viewModel.spendingForCategory(category)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Theme.Colors.secondaryBackground)
                                    .frame(height: 8)
                                
                                Capsule()
                                    .fill(status.color)
                                    .frame(width: geometry.size.width * CGFloat(min(spent / budget, 1.0)), height: 8)
                            }
                        }
                        .frame(height: 8)
                        
                        HStack {
                            Text("\(formatCurrency(spent, currency: viewModel.appState.selectedCurrency)) spent")
                            Spacer()
                            Text("of \(formatCurrency(budget, currency: viewModel.appState.selectedCurrency))")
                        }
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            
            // Quick Stats
            Section("Statistics") {
                MetricRow(
                    icon: "number.circle.fill",
                    title: "Transactions",
                    value: "\(stats.transactionCount)",
                    color: Theme.Colors.secondaryText
                )
                
                MetricRow(
                    icon: "percent",
                    title: "% of Total",
                    value: String(format: "%.0f%%", stats.percentOfTotal * 100),
                    color: Theme.Colors.primary
                )
                
                MetricRow(
                    icon: "chart.bar.fill",
                    title: "Monthly Average",
                    value: formatCurrency(monthlyAverage, currency: viewModel.appState.selectedCurrency),
                    color: Theme.Colors.primary
                )
                
                if stats.transactionCount > 0 {
                    MetricRow(
                        icon: "divide.circle.fill",
                        title: "Avg per Transaction",
                        value: formatCurrency(stats.averageTransaction, currency: viewModel.appState.selectedCurrency),
                        color: category.colorValue
                    )
                }
            }
            
            // Last Transaction
            if let last = lastTransaction {
                Section("Last Transaction") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(last.title.isEmpty ? "No title" : last.title)
                                .font(Theme.Typography.headline)
                            Text(formatDate(last.date))
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        Spacer()
                        Text(formatCurrency(last.amount, currency: viewModel.appState.selectedCurrency))
                            .font(Theme.Typography.transactionAmount)
                            .foregroundColor(category.type == .expense ? Theme.Colors.expense : Theme.Colors.income)
                    }
                }
            }
            
            // Recent Transactions (filtered by time range)
            Section("Recent Transactions") {
                if periodTransactions.isEmpty {
                    Text("No transactions in this period")
                        .foregroundColor(Theme.Colors.secondaryText)
                } else {
                    ForEach(Array(periodTransactions.prefix(10))) { transaction in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(transaction.title.isEmpty ? category.name : transaction.title)
                                    .font(Theme.Typography.body)
                                Text(formatDate(transaction.date))
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                            Spacer()
                            Text(formatCurrency(transaction.amount, currency: viewModel.appState.selectedCurrency))
                                .font(Theme.Typography.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: EditCategoryView(viewModel: viewModel, category: category)) {
                    Text("Edit")
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(Theme.Colors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundColor(color)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }
}

// MARK: - Add Account View
struct AddAccountView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedType: AccountType = .checking
    @State private var initialBalance = ""
    @State private var selectedIcon = "building.columns.fill"
    @State private var selectedColorIndex = 0
    @State private var note = ""
    
    private let accountIcons = [
        "building.columns.fill", "banknote.fill", "creditcard.fill", "wallet.bifold.fill",
        "chart.line.uptrend.xyaxis", "wallet.pass.fill", "creditcard.and.123",
        "briefcase.fill", "bag.fill", "cart.fill", "safe.fill", "dollarsign.bank.building.fill",
        "bitcoinsign.circle.fill", "eurosign.circle.fill", "yensign.circle.fill",
        "sterlingsign.circle.fill", "pesosign.circle.fill", "rublesign.circle.fill",
        "indianrupeesign.circle.fill", "turkishlirasign.circle.fill", "francsign.circle.fill",
        "dollarsign.arrow.circlepath", "arrow.trianglehead.2.counterclockwise.rotate.90.circle.fill",
        "chart.bar.fill", "percent", "banknote", "creditcard.viewfinder"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Preview
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.categoryColors[selectedColorIndex].opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: selectedIcon)
                                .font(.system(size: 24))
                                .foregroundColor(Theme.Colors.categoryColors[selectedColorIndex])
                        }
                        Text(name.isEmpty ? "Account Name" : name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(name.isEmpty ? Color(uiColor: .tertiaryLabel) : Color(uiColor: .label))
                    }
                    .padding(.vertical, 16)
                    
                    // Details
                    VStack(spacing: 0) {
                        HStack {
                            Text("Name")
                                .font(.system(size: 15))
                                .foregroundColor(Color(uiColor: .label))
                            Spacer()
                            TextField("Account Name", text: $name)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color(uiColor: .label))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        
                        Divider().padding(.leading, 16)
                        
                        Picker("Type", selection: $selectedType) {
                            ForEach(AccountType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        
                        Divider().padding(.leading, 16)
                        
                        HStack {
                            Text("Balance")
                                .font(.system(size: 15))
                                .foregroundColor(Color(uiColor: .label))
                            Spacer()
                            TextField("0.00", text: $initialBalance)
                                .font(.system(size: 15))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text(currencySymbol)
                                .font(.system(size: 13))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        
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
                        .padding(.horizontal, 16).padding(.vertical, 12)
                    }
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                    
                    // Icon
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Icon")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(accountIcons, id: \.self) { icon in
                                IconPickerItem(
                                    icon: icon,
                                    color: Theme.Colors.categoryColors[selectedColorIndex],
                                    isSelected: selectedIcon == icon,
                                    action: { selectedIcon = icon; Haptics.selection() }
                                )
                            }
                        }
                        .padding(14)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }
                    
                    // Color
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(0..<Theme.Colors.categoryColors.count, id: \.self) { index in
                                ColorPickerItem(
                                    color: Theme.Colors.categoryColors[index],
                                    isSelected: selectedColorIndex == index,
                                    action: { selectedColorIndex = index; Haptics.selection() }
                                )
                            }
                        }
                        .padding(14)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addAccount() }
                        .disabled(name.isEmpty)
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
    
    private func addAccount() {
        let balance = Double(initialBalance) ?? 0
        let colorHex = Theme.Colors.categoryColors[selectedColorIndex].toHex() ?? "#007AFF"
        
        let account = Account(
            name: name,
            type: selectedType,
            icon: selectedIcon,
            color: colorHex,
            initialBalance: balance,
            note: note.isEmpty ? nil : note
        )
        
        viewModel.addAccount(account)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Add Category View
struct AddCategoryView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedType: CategoryType = .expense
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColorIndex = 0
    @State private var note = ""
    
    private let categoryIcons = [
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "mug.fill", "carrot.fill", "birthday.cake.fill",
        "cart.fill", "basket.fill", "bag.fill", "storefront.fill", "shippingbox.fill", "gift.fill",
        "car.fill", "bus.fill", "tram.fill", "bicycle", "airplane", "fuelpump.fill", "parkingsign.circle.fill",
        "film.fill", "tv.fill", "gamecontroller.fill", "music.note", "ticket.fill", "theatermasks.fill",
        "heart.fill", "cross.fill", "pills.fill", "stethoscope", "dumbbell.fill", "figure.run",
        "house.fill", "bolt.fill", "drop.fill", "flame.fill", "wifi", "washer.fill", "bed.double.fill",
        "briefcase.fill", "laptopcomputer", "desktopcomputer", "printer.fill", "keyboard.fill",
        "graduationcap.fill", "book.fill", "pencil", "backpack.fill", "books.vertical.fill",
        "dollarsign.circle.fill", "chart.line.uptrend.xyaxis", "banknote.fill", "percent",
        "pawprint.fill", "leaf.fill", "camera.fill", "sparkles", "star.fill", "tag.fill", "lightbulb.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Preview
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.categoryColors[selectedColorIndex].opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: selectedIcon)
                                .font(.system(size: 24))
                                .foregroundColor(Theme.Colors.categoryColors[selectedColorIndex])
                        }
                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(name.isEmpty ? Color(uiColor: .tertiaryLabel) : Color(uiColor: .label))
                    }
                    .padding(.vertical, 16)
                    
                    // Details
                    VStack(spacing: 0) {
                        HStack {
                            Text("Name")
                                .font(.system(size: 15))
                                .foregroundColor(Color(uiColor: .label))
                            Spacer()
                            TextField("Category Name", text: $name)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        
                        Divider().padding(.leading, 16)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Type")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(uiColor: .label))
                                Spacer()
                            }
                            Picker("Type", selection: $selectedType) {
                                Text("Expense").tag(CategoryType.expense)
                                Text("Income").tag(CategoryType.income)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        
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
                        .padding(.horizontal, 16).padding(.vertical, 12)
                    }
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                    
                    // Icon
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Icon")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                            ForEach(categoryIcons, id: \.self) { icon in
                                IconPickerItem(
                                    icon: icon,
                                    color: Theme.Colors.categoryColors[selectedColorIndex],
                                    isSelected: selectedIcon == icon,
                                    action: { selectedIcon = icon; Haptics.selection() }
                                )
                            }
                        }
                        .padding(12)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }
                    
                    // Color
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(0..<Theme.Colors.categoryColors.count, id: \.self) { index in
                                ColorPickerItem(
                                    color: Theme.Colors.categoryColors[index],
                                    isSelected: selectedColorIndex == index,
                                    action: { selectedColorIndex = index; Haptics.selection() }
                                )
                            }
                        }
                        .padding(14)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addCategory() }
                        .disabled(name.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func addCategory() {
        let colorHex = Theme.Colors.categoryColors[selectedColorIndex].toHex() ?? "#007AFF"
        
        let category = Category(
            name: name,
            icon: selectedIcon,
            color: colorHex,
            type: selectedType,
            sortOrder: viewModel.categories.count,
            note: note.isEmpty ? nil : note
        )
        
        viewModel.addCategory(category)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Edit Category View (with Note field)
struct EditCategoryView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    let category: Category
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColorIndex: Int
    @State private var note: String
    
    // SF Symbols 7 category icons
    private let categoryIcons = [
        // Food & Dining
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "mug.fill", "carrot.fill", "birthday.cake.fill",
        // Shopping
        "cart.fill", "basket.fill", "bag.fill", "storefront.fill", "shippingbox.fill", "gift.fill",
        // Transport
        "car.fill", "bus.fill", "tram.fill", "bicycle", "airplane", "fuelpump.fill", "parkingsign.circle.fill",
        // Entertainment
        "film.fill", "tv.fill", "gamecontroller.fill", "music.note", "ticket.fill", "theatermasks.fill",
        // Health
        "heart.fill", "cross.fill", "pills.fill", "stethoscope", "dumbbell.fill", "figure.run",
        // Home
        "house.fill", "bolt.fill", "drop.fill", "flame.fill", "wifi", "washer.fill", "bed.double.fill",
        // Work
        "briefcase.fill", "laptopcomputer", "desktopcomputer", "printer.fill", "keyboard.fill",
        // Education
        "graduationcap.fill", "book.fill", "pencil", "backpack.fill", "books.vertical.fill",
        // Finance
        "dollarsign.circle.fill", "chart.line.uptrend.xyaxis", "banknote.fill", "percent",
        // Other
        "pawprint.fill", "leaf.fill", "camera.fill", "sparkles", "star.fill", "tag.fill", "lightbulb.fill"
    ]
    
    init(viewModel: BalanceViewModel, category: Category) {
        self.viewModel = viewModel
        self.category = category
        _name = State(initialValue: category.name)
        _selectedIcon = State(initialValue: category.icon)
        _note = State(initialValue: category.note ?? "")
        
        var colorIndex = 0
        for (index, color) in Theme.Colors.categoryColors.enumerated() {
            if let hex = color.toHex(), hex.uppercased() == category.color.uppercased() {
                colorIndex = index
                break
            }
        }
        _selectedColorIndex = State(initialValue: colorIndex)
    }
    
    var body: some View {
        Form {
            Section("Category Details") {
                TextField("Category Name", text: $name)
                
                TextField("Note (optional)", text: $note)
                
                HStack {
                    Text("Type")
                    Spacer()
                    Text(category.type.rawValue)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            
            Section("Icon") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Theme.Spacing.md) {
                    ForEach(categoryIcons, id: \.self) { icon in
                        IconPickerItem(
                            icon: icon,
                            color: Theme.Colors.categoryColors[selectedColorIndex],
                            isSelected: selectedIcon == icon,
                            action: {
                                selectedIcon = icon
                                Haptics.selection()
                            }
                        )
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            
            Section("Color") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Theme.Spacing.sm) {
                    ForEach(0..<Theme.Colors.categoryColors.count, id: \.self) { index in
                        ColorPickerItem(
                            color: Theme.Colors.categoryColors[index],
                            isSelected: selectedColorIndex == index,
                            action: {
                                selectedColorIndex = index
                                Haptics.selection()
                            }
                        )
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            
            if !category.isSystem {
                Section {
                    Button("Delete Category", role: .destructive) {
                        viewModel.deleteCategory(category)
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Edit Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { saveChanges() }
                    .fontWeight(.semibold)
            }
        }
    }
    
    private func saveChanges() {
        let colorHex = Theme.Colors.categoryColors[selectedColorIndex].toHex() ?? category.color
        
        var updated = category
        updated.name = name
        updated.icon = selectedIcon
        updated.color = colorHex
        updated.note = note.isEmpty ? nil : note
        
        viewModel.updateCategory(updated)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Account Detail View
struct AccountDetailView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let account: Account
    
    private var balance: Double {
        viewModel.balanceForAccount(account)
    }
    
    private var balanceColor: Color {
        if balance == 0 {
            return Theme.Colors.primaryText
        } else if balance > 0 {
            return Theme.Colors.income
        } else {
            return Theme.Colors.expense
        }
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: Theme.Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(account.colorValue.opacity(0.15))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: account.icon)
                                .font(.title)
                                .foregroundColor(account.colorValue)
                        }
                        
                        Text(account.name)
                            .font(Theme.Typography.title2)
                        
                        if let note = account.note, !note.isEmpty {
                            Text(note)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        
                        Text(formatCurrency(balance, currency: viewModel.appState.selectedCurrency))
                            .font(Theme.Typography.balanceAmount)
                            .foregroundColor(balanceColor)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
            Section("Recent Transactions") {
                let transactions = viewModel.transactionsForAccount(account).prefix(10)
                if transactions.isEmpty {
                    Text("No transactions yet")
                        .foregroundColor(Theme.Colors.secondaryText)
                } else {
                    ForEach(Array(transactions)) { transaction in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(transaction.title.isEmpty ? (viewModel.getCategory(by: transaction.categoryId)?.name ?? transaction.type.rawValue) : transaction.title)
                                    .font(Theme.Typography.body)
                                Text(formatDate(transaction.date))
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                            Spacer()
                            Text(formatSignedAmount(transaction))
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(transaction.type == .expense ? Theme.Colors.expense : Theme.Colors.income)
                        }
                    }
                }
            }
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: EditAccountView(viewModel: viewModel, account: account)) {
                    Text("Edit")
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatSignedAmount(_ transaction: Transaction) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.appState.selectedCurrency
        let formatted = formatter.string(from: NSNumber(value: transaction.amount)) ?? "$0.00"
        return transaction.type == .expense ? "-\(formatted)" : "+\(formatted)"
    }
}

// MARK: - Edit Account View (with Note field, fixed color picker)
struct EditAccountView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    let account: Account
    
    @State private var name: String
    @State private var selectedType: AccountType
    @State private var selectedIcon: String
    @State private var selectedColorIndex: Int
    @State private var note: String
    
    // SF Symbols 7 account icons
    private let accountIcons = [
        "building.columns.fill", "banknote.fill", "creditcard.fill", "wallet.bifold.fill",
        "chart.line.uptrend.xyaxis", "wallet.pass.fill", "creditcard.and.123",
        "briefcase.fill", "bag.fill", "cart.fill", "safe.fill", "dollarsign.bank.building.fill",
        "bitcoinsign.circle.fill", "eurosign.circle.fill", "yensign.circle.fill",
        "sterlingsign.circle.fill", "pesosign.circle.fill", "rublesign.circle.fill",
        "indianrupeesign.circle.fill", "turkishlirasign.circle.fill", "francsign.circle.fill",
        "dollarsign.arrow.circlepath", "arrow.trianglehead.2.counterclockwise.rotate.90.circle.fill",
        "chart.bar.fill", "percent", "banknote", "creditcard.viewfinder"
    ]
    
    init(viewModel: BalanceViewModel, account: Account) {
        self.viewModel = viewModel
        self.account = account
        _name = State(initialValue: account.name)
        _selectedType = State(initialValue: account.type)
        _selectedIcon = State(initialValue: account.icon)
        _note = State(initialValue: account.note ?? "")
        
        var colorIndex = 0
        for (index, color) in Theme.Colors.categoryColors.enumerated() {
            if let hex = color.toHex(), hex.uppercased() == account.color.uppercased() {
                colorIndex = index
                break
            }
        }
        _selectedColorIndex = State(initialValue: colorIndex)
    }
    
    var body: some View {
        Form {
            Section("Account Details") {
                TextField("Account Name", text: $name)
                
                Picker("Type", selection: $selectedType) {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                TextField("Note (optional)", text: $note)
            }
            
            Section("Icon") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Theme.Spacing.md) {
                    ForEach(accountIcons, id: \.self) { icon in
                        IconPickerItem(
                            icon: icon,
                            color: Theme.Colors.categoryColors[selectedColorIndex],
                            isSelected: selectedIcon == icon,
                            action: {
                                selectedIcon = icon
                                Haptics.selection()
                            }
                        )
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            
            Section("Color") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Theme.Spacing.sm) {
                    ForEach(0..<Theme.Colors.categoryColors.count, id: \.self) { index in
                        ColorPickerItem(
                            color: Theme.Colors.categoryColors[index],
                            isSelected: selectedColorIndex == index,
                            action: {
                                selectedColorIndex = index
                                Haptics.selection()
                            }
                        )
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            
            if viewModel.accounts.count > 1 {
                Section {
                    Button("Delete Account", role: .destructive) {
                        viewModel.deleteAccount(account)
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Edit Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { saveChanges() }
                    .fontWeight(.semibold)
            }
        }
    }
    
    private func saveChanges() {
        let colorHex = Theme.Colors.categoryColors[selectedColorIndex].toHex() ?? account.color
        
        var updated = account
        updated.name = name
        updated.type = selectedType
        updated.icon = selectedIcon
        updated.color = colorHex
        updated.note = note.isEmpty ? nil : note
        
        viewModel.updateAccount(updated)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Icon Picker Item
struct IconPickerItem: View {
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? color : color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : color)
            }
        }
    }
}

// MARK: - Color Picker Item
struct ColorPickerItem: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Theme.Colors.primaryText : Color.clear, lineWidth: 3)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isSelected ? 1 : 0)
                )
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
