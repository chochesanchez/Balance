import SwiftUI

// MARK: - Wallet View
struct WalletView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var selectedSegment = 0
    @State private var showingAddAccount = false
    @State private var showingAddCategory = false
    @State private var showingSearch = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if showingSearch {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    TextField("Search \(selectedSegment == 0 ? "accounts" : "categories")...", text: $searchText)
                        .font(.system(size: 15))
                    
                    Button(action: {
                        searchText = ""
                        showingSearch = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
                .padding(10)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            Picker("View", selection: $selectedSegment) {
                Text("Accounts").tag(0)
                Text("Categories").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .onChange(of: selectedSegment) { oldValue, newValue in
                searchText = ""
            }
            
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
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.snappy) { showingSearch.toggle() }
                        if !showingSearch { searchText = "" }
                        Haptics.light()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(showingSearch ? Theme.Colors.primary : Color(uiColor: .label))
                    }
                    
                    Button(action: {
                        if selectedSegment == 0 { showingAddAccount = true }
                        else { showingAddCategory = true }
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
    @State private var showingAddPot = false
    
    private var filteredAccounts: [Account] {
        if searchText.isEmpty { return viewModel.accounts }
        return viewModel.accounts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var totalBalance: Double { viewModel.totalBalance }
    
    private var totalIncome: Double {
        viewModel.transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpense: Double {
        viewModel.transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Total Balance Header
                VStack(spacing: 4) {
                    Text("Total Balance")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Text(formatCurrency(totalBalance, currency: viewModel.appState.selectedCurrency))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label))
                        .contentTransition(.numericText(value: totalBalance))
                        .animation(.snappy, value: totalBalance)
                    
                    HStack(spacing: 20) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.Colors.income)
                            Text(formatCompactAmount(totalIncome, currency: viewModel.appState.selectedCurrency))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.Colors.income)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.Colors.expense)
                            Text(formatCompactAmount(totalExpense, currency: viewModel.appState.selectedCurrency))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.Colors.expense)
                        }
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // Accounts
                VStack(alignment: .leading, spacing: 10) {
                    Text("MY ACCOUNTS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .padding(.horizontal, 20)
                    
                    if filteredAccounts.isEmpty {
                        WalletEmptyState(
                            icon: "wallet.pass.fill",
                            title: "No accounts yet",
                            message: searchText.isEmpty ? "Add your first account to start tracking" : "No accounts match your search",
                            buttonTitle: searchText.isEmpty ? "Add Account" : nil,
                            action: { showingAddAccount = true }
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(filteredAccounts.enumerated()), id: \.element.id) { index, account in
                                NavigationLink(destination: AccountDetailView(viewModel: viewModel, account: account)) {
                                    AccountRowView(
                                        account: account,
                                        balance: viewModel.balanceForAccount(account),
                                        currency: viewModel.appState.selectedCurrency
                                    )
                                }
                                
                                if index < filteredAccounts.count - 1 {
                                    Divider().padding(.leading, 68)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }
                }
                
                // Savings Pots
                VStack(alignment: .leading, spacing: 10) {
                    Text("SAVINGS POTS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .padding(.horizontal, 20)
                    
                    if viewModel.envelopes.isEmpty {
                        WalletEmptyState(
                            icon: "tray.2.fill",
                            title: "No savings pots",
                            message: "Create pots for Savings, Investment, etc.",
                            buttonTitle: "Add Pot",
                            action: { showingAddPot = true }
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.envelopes.enumerated()), id: \.element.id) { index, pot in
                                NavigationLink(destination: GoalDetailView(viewModel: viewModel, goal: pot)) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(pot.colorValue.opacity(0.12))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: pot.icon)
                                                .font(.system(size: 18))
                                                .foregroundColor(pot.colorValue)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(pot.title)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(Color(uiColor: .label))
                                            Text("Savings Pot")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(uiColor: .secondaryLabel))
                                        }
                                        
                                        Spacer()
                                        
                                        Text(formatCurrency(pot.currentAmount, currency: viewModel.appState.selectedCurrency))
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color(uiColor: .label))
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(Color(uiColor: .quaternaryLabel))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                
                                if index < viewModel.envelopes.count - 1 {
                                    Divider().padding(.leading, 68)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $showingAddPot) {
            NavigationStack {
                QuickAddPotSheet(viewModel: viewModel)
            }
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Account Row View
struct AccountRowView: View {
    let account: Account
    let balance: Double
    let currency: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(account.colorValue.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: account.icon)
                    .font(.system(size: 18))
                    .foregroundColor(account.colorValue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                    Text(account.type.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
            
            Spacer()
            
            Text(formatCurrency(balance, currency: currency))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color(uiColor: .label))
            
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(uiColor: .quaternaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Categories List View
struct CategoriesListView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let searchText: String
    @Binding var showingAddCategory: Bool
    
    private var filteredExpenseCategories: [Category] {
        let cats = viewModel.expenseCategories
        if searchText.isEmpty { return cats }
        return cats.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredIncomeCategories: [Category] {
        let cats = viewModel.incomeCategories
        if searchText.isEmpty { return cats }
        return cats.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var hasAnyCategories: Bool { !viewModel.categories.isEmpty }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            if !hasAnyCategories {
                WalletEmptyState(
                    icon: "square.grid.2x2",
                    title: "No Categories Yet",
                    message: "Create categories to organize\nyour transactions",
                    buttonTitle: "Add Category",
                    action: { showingAddCategory = true }
                )
                .padding(.top, 40)
            } else {
                VStack(spacing: 20) {
                    if !filteredExpenseCategories.isEmpty {
                CategorySection(
                            title: "Expense",
                    categories: filteredExpenseCategories,
                    viewModel: viewModel
                )
                    }
                
                    if !filteredIncomeCategories.isEmpty {
                CategorySection(
                            title: "Income",
                    categories: filteredIncomeCategories,
                    viewModel: viewModel
                )
                    }
                    
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
                .padding(.bottom, 16)
            }
        }
    }
}

struct CategorySection: View {
    let title: String
    let categories: [Category]
    @ObservedObject var viewModel: BalanceViewModel
    
    private var sectionTotal: Double {
        categories.reduce(0) { sum, cat in
            sum + viewModel.transactionsForCategory(cat).reduce(0) { $0 + $1.amount }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                
                Spacer()
                
                Text("\(categories.count) categories")
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            .padding(.horizontal, 20)
            
                VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        NavigationLink(destination: CategoryMetricsView(viewModel: viewModel, category: category)) {
                        CategoryRowView(category: category, viewModel: viewModel)
                    }
                    
                    if index < categories.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(14)
            .padding(.horizontal, 16)
        }
    }
}

struct CategoryRowView: View {
    let category: Category
    @ObservedObject var viewModel: BalanceViewModel
    
    private var txCount: Int {
        viewModel.transactionsForCategory(category).count
    }
    
    private var totalAmount: Double {
        viewModel.transactionsForCategory(category).reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        HStack(spacing: 12) {
                Image(systemName: category.icon)
                .font(.system(size: 16))
                    .foregroundColor(category.colorValue)
                .frame(width: 36, height: 36)
                .background(category.colorValue.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(uiColor: .label))
                
                if txCount > 0 {
                    Text("\(txCount) transactions \u{2022} \(formatCurrency(totalAmount, currency: viewModel.appState.selectedCurrency))")
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .lineLimit(1)
                } else if let note = category.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(uiColor: .quaternaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Wallet Empty State
struct WalletEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(uiColor: .label))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .multilineTextAlignment(.center)
            
            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 180, height: 44)
                        .background(Theme.Colors.primary)
                        .cornerRadius(12)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Category Metrics View
struct CategoryMetricsView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let category: Category
    @State private var selectedTimeRange: TimeRange = .monthly
    
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
            // Header
                VStack(spacing: 10) {
                        ZStack {
                            Circle()
                            .fill(category.colorValue.opacity(0.12))
                            .frame(width: 72, height: 72)
                            
                            Image(systemName: category.icon)
                            .font(.system(size: 30))
                                .foregroundColor(category.colorValue)
                        }
                        
                        Text(category.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(uiColor: .label))
                        
                        Text(category.type.rawValue)
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        
                        if let note = category.note, !note.isEmpty {
                            Text(note)
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // Period Selector + Amount
                VStack(spacing: 14) {
                    TimeScopeSelector(selected: $selectedTimeRange, showAllOptions: false)
                    
                    VStack(spacing: 4) {
                        Text("Total \(selectedTimeRange.shortTitle)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        
                        Text(formatCurrency(stats.total, currency: viewModel.appState.selectedCurrency))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(category.colorValue)
                            .contentTransition(.numericText(value: stats.total))
                            .animation(.snappy, value: stats.total)
                        
                        if let delta = stats.deltaFromPrevious, abs(delta) > 0.01 {
                            HStack(spacing: 4) {
                                Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("\(Int(abs(delta * 100)))% vs last period")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(category.type == .expense ? (delta >= 0 ? Theme.Colors.expense : Theme.Colors.income) : (delta >= 0 ? Theme.Colors.income : Theme.Colors.expense))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // Budget Status
            if let status = budgetStatus, category.budget != nil {
                    let budget = category.budget ?? 0
                    let spent = viewModel.spendingForCategory(category)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Budget")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(uiColor: .label))
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: status.icon)
                                    .font(.system(size: 11))
                                Text(status.label)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(status.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(status.color.opacity(0.12))
                            .cornerRadius(6)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(uiColor: .tertiarySystemFill))
                                    .frame(height: 6)
                                
                                Capsule()
                                    .fill(status.color)
                                    .frame(width: geo.size.width * CGFloat(min(spent / budget, 1.0)), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        HStack {
                            Text("\(formatCurrency(spent, currency: viewModel.appState.selectedCurrency)) spent")
                                .font(.system(size: 12))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                            Spacer()
                            Text("of \(formatCurrency(budget, currency: viewModel.appState.selectedCurrency))")
                                .font(.system(size: 12))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                    }
                    .padding(18)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                
                // Statistics Grid
                VStack(alignment: .leading, spacing: 14) {
                    Text("Statistics")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        WalletStatCard(
                    icon: "number.circle.fill",
                    title: "Transactions",
                    value: "\(stats.transactionCount)",
                            color: category.colorValue
                )
                
                        WalletStatCard(
                    icon: "percent",
                    title: "% of Total",
                    value: String(format: "%.0f%%", stats.percentOfTotal * 100),
                    color: Theme.Colors.primary
                )
                
                        WalletStatCard(
                    icon: "chart.bar.fill",
                            title: "Monthly Avg",
                            value: formatCompactAmount(monthlyAverage, currency: viewModel.appState.selectedCurrency),
                            color: Theme.Colors.recurring
                )
                
                if stats.transactionCount > 0 {
                            WalletStatCard(
                        icon: "divide.circle.fill",
                                title: "Avg / Transaction",
                                value: formatCompactAmount(stats.averageTransaction, currency: viewModel.appState.selectedCurrency),
                                color: Theme.Colors.transfer
                            )
                        }
                    }
                }
                .padding(18)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // Recent Transactions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Transactions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                    
                if periodTransactions.isEmpty {
                    Text("No transactions in this period")
                            .font(.system(size: 13))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                } else {
                        VStack(spacing: 0) {
                            ForEach(Array(periodTransactions.prefix(10).enumerated()), id: \.element.id) { index, tx in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tx.title.isEmpty ? category.name : tx.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(uiColor: .label))
                                        Text(formatDate(tx.date))
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                            }
                            Spacer()
                                    Text(formatCurrency(tx.amount, currency: viewModel.appState.selectedCurrency))
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(category.type == .expense ? Theme.Colors.expense : Theme.Colors.income)
                                }
                                .padding(.vertical, 8)
                                
                                if index < min(periodTransactions.count, 10) - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(18)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.bottom, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: EditCategoryView(viewModel: viewModel, category: category)) {
                    Text("Edit")
                        .font(.system(size: 15, weight: .medium))
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

private struct WalletStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(Color(uiColor: .label))
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Account Detail View
struct AccountDetailView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    let account: Account
    
    private var balance: Double { viewModel.balanceForAccount(account) }
    
    private var accountTransactions: [Transaction] {
        viewModel.transactionsForAccount(account).sorted { $0.date > $1.date }
    }
    
    private var accountIncome: Double {
        accountTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var accountExpense: Double {
        accountTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var monthlyTransactions: [Transaction] {
        let cal = Calendar.current
        let now = Date()
        guard let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return [] }
        return accountTransactions.filter { $0.date >= startOfMonth }
    }
    
    private var monthlyIncome: Double {
        monthlyTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var monthlyExpense: Double {
        monthlyTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(account.colorValue.opacity(0.12))
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: account.icon)
                            .font(.system(size: 30))
                            .foregroundColor(account.colorValue)
                    }
                    
                    Text(account.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text(account.type.rawValue)
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    if let note = account.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                    
                    Text(formatCurrency(balance, currency: viewModel.appState.selectedCurrency))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label))
                        .contentTransition(.numericText(value: balance))
                        .animation(.snappy, value: balance)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // This Month Overview
                VStack(alignment: .leading, spacing: 14) {
                    Text("This Month")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                    
                    HStack(spacing: 10) {
                        AccountMetricPill(
                            icon: "arrow.down",
                            label: "Income",
                            amount: formatCompactAmount(monthlyIncome, currency: viewModel.appState.selectedCurrency),
                            color: Theme.Colors.income
                        )
                        
                        AccountMetricPill(
                            icon: "arrow.up",
                            label: "Expense",
                            amount: formatCompactAmount(monthlyExpense, currency: viewModel.appState.selectedCurrency),
                            color: Theme.Colors.expense
                        )
                        
                        AccountMetricPill(
                            icon: "number",
                            label: "Records",
                            amount: "\(monthlyTransactions.count)",
                            color: Theme.Colors.primary
                        )
                    }
                }
                .padding(18)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // All-Time Stats
                VStack(alignment: .leading, spacing: 14) {
                    Text("All-Time")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        WalletStatCard(
                            icon: "arrow.down.circle.fill",
                            title: "Total Income",
                            value: formatCompactAmount(accountIncome, currency: viewModel.appState.selectedCurrency),
                            color: Theme.Colors.income
                        )
                        
                        WalletStatCard(
                            icon: "arrow.up.circle.fill",
                            title: "Total Expense",
                            value: formatCompactAmount(accountExpense, currency: viewModel.appState.selectedCurrency),
                            color: Theme.Colors.expense
                        )
                        
                        WalletStatCard(
                            icon: "number.circle.fill",
                            title: "Transactions",
                            value: "\(accountTransactions.count)",
                            color: account.colorValue
                        )
                        
                        WalletStatCard(
                            icon: "banknote.fill",
                            title: "Initial Balance",
                            value: formatCompactAmount(account.initialBalance, currency: viewModel.appState.selectedCurrency),
                            color: Color(uiColor: .secondaryLabel)
                        )
                    }
                }
                .padding(18)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // Recent Transactions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Transactions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                    
                    if accountTransactions.isEmpty {
                        Text("No transactions yet")
                            .font(.system(size: 13))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(accountTransactions.prefix(10).enumerated()), id: \.element.id) { index, tx in
                                HStack(spacing: 12) {
                                    let cat = viewModel.getCategory(by: tx.categoryId)
                                    
                                    Image(systemName: cat?.icon ?? "circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(cat?.colorValue ?? Color(uiColor: .secondaryLabel))
                                        .frame(width: 30, height: 30)
                                        .background((cat?.colorValue ?? Color(uiColor: .secondaryLabel)).opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tx.title.isEmpty ? (cat?.name ?? tx.type.rawValue) : tx.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(uiColor: .label))
                                        Text(formatRelativeDate(tx.date))
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                                    }
            
            Spacer()
            
                                    Text("\(tx.type == .expense ? "-" : "+")\(formatCurrency(tx.amount, currency: viewModel.appState.selectedCurrency))")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(tx.type == .expense ? Theme.Colors.expense : Theme.Colors.income)
                                }
                                .padding(.vertical, 8)
                                
                                if index < min(accountTransactions.count, 10) - 1 {
                                    Divider().padding(.leading, 42)
                                }
                            }
                        }
                    }
                }
                .padding(18)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.bottom, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: EditAccountView(viewModel: viewModel, account: account)) {
                    Text("Edit")
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
        .onChange(of: viewModel.accounts.map(\.id)) { _, newIds in
            if !newIds.contains(account.id) { dismiss() }
        }
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

private struct AccountMetricPill: View {
    let icon: String
    let label: String
    let amount: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            Text(amount)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color(uiColor: .label))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.06))
        .cornerRadius(12)
    }
}

// MARK: - Add Account View
struct AddAccountView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedType: AccountType = .cash
    @State private var initialBalance = ""
    @State private var selectedIcon = "dollarsign.circle.fill"
    @State private var selectedColorIndex = 13
    @State private var note = ""
    @State private var showingCurrencyPicker = false
    
    private let accountIcons = [
        "building.columns.fill", "banknote.fill", "creditcard.fill", "wallet.pass.fill",
        "dollarsign.circle.fill", "lock.fill", "briefcase.fill", "bag.fill",
        "chart.line.uptrend.xyaxis", "chart.bar.fill", "iphone", "globe",
        "bitcoinsign.circle.fill", "eurosign.circle.fill", "sterlingsign.circle.fill",
        "yensign.circle.fill", "pesosign.circle.fill", "indianrupeesign.circle.fill",
        "coloncurrencysign.circle.fill", "francsign.circle.fill",
        "house.fill", "car.fill", "star.fill", "heart.fill",
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.categoryColors[selectedColorIndex].opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: selectedIcon)
                                .font(.system(size: 24))
                                .foregroundColor(Theme.Colors.categoryColors[selectedColorIndex])
                        }
                        Text(name.isEmpty ? "Account Name" : name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(name.isEmpty ? Color(uiColor: .tertiaryLabel) : Color(uiColor: .label))
                        
                        Text(selectedType.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    .padding(.vertical, 16)
                    
                    VStack(spacing: 0) {
                        FormRow(label: "Name") {
                    TextField("Account Name", text: $name)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.trailing)
                        }
                        
                        Divider().padding(.leading, 16)
                        
                        HStack {
                            Text("Type")
                                .font(.system(size: 15))
                                .foregroundColor(Color(uiColor: .label))
                            Spacer()
                    Picker("Type", selection: $selectedType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                            .labelsHidden()
                            .tint(Color(uiColor: .secondaryLabel))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        
                        Divider().padding(.leading, 16)
                        
                        FormRow(label: "Balance") {
                            TextField("0.00", text: $initialBalance)
                                .font(.system(size: 15))
                            .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            
                            Button(action: { showingCurrencyPicker = true }) {
                                Text(viewModel.appState.selectedCurrency)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.Colors.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Theme.Colors.primary.opacity(0.08))
                                    .cornerRadius(6)
                            }
                        }
                        
                        Divider().padding(.leading, 16)
                        
                        FormRow(label: "Note") {
                            TextField("Optional", text: $note)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                    
                    PickerSection(title: "Icon") {
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
                }
                
                    PickerSection(title: "Color") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                        ForEach(0..<Theme.Colors.categoryColors.count, id: \.self) { index in
                            ColorPickerItem(
                                color: Theme.Colors.categoryColors[index],
                                isSelected: selectedColorIndex == index,
                                    action: { selectedColorIndex = index; Haptics.selection() }
                            )
                        }
                    }
                }
            }
                .padding(.top, 8)
                .padding(.bottom, 32)
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
            .sheet(isPresented: $showingCurrencyPicker) {
                CurrencyPickerSheet(selectedCurrency: $viewModel.appState.selectedCurrency)
                    .presentationDetents([.medium, .large])
            }
            .onChange(of: viewModel.appState.selectedCurrency) { _, _ in
                viewModel.saveData()
            }
        }
    }
    
    private func addAccount() {
        let balance = Double(initialBalance) ?? 0
        let colorHex = Theme.Colors.categoryColors[selectedColorIndex].toHex() ?? "#007AFF"
        let account = Account(
            name: name, type: selectedType, icon: selectedIcon,
            color: colorHex, initialBalance: balance,
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
    @State private var budgetText = ""
    @State private var showAllIcons = false
    
    private let categoryIcons = [
        // Food & Dining
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "mug.fill", "carrot.fill", "birthday.cake.fill",
        // Shopping & Fashion
        "cart.fill", "basket.fill", "bag.fill", "storefront.fill", "shippingbox.fill", "gift.fill",
        "tshirt.fill", "shoe.fill", "eyeglasses", "crown.fill",
        // Transport
        "car.fill", "bus.fill", "tram.fill", "bicycle", "airplane", "fuelpump.fill",
        // Entertainment
        "film.fill", "tv.fill", "gamecontroller.fill", "music.note", "ticket.fill", "theatermasks.fill",
        // Health & Fitness & Body
        "heart.fill", "cross.fill", "pills.fill", "stethoscope", "dumbbell.fill", "figure.run",
        "comb.fill", "scissors", "figure.stand", "face.smiling.fill",
        // Home & Utilities
        "house.fill", "bolt.fill", "drop.fill", "flame.fill", "wifi", "washer.fill",
        // Work
        "briefcase.fill", "laptopcomputer", "desktopcomputer", "printer.fill", "keyboard.fill", "doc.fill",
        // Education
        "graduationcap.fill", "book.fill", "pencil", "backpack.fill", "books.vertical.fill", "brain.fill",
        // Finance
        "dollarsign.circle.fill", "chart.line.uptrend.xyaxis", "banknote.fill", "percent", "building.columns.fill", "creditcard.fill",
        // Pets
        "pawprint.fill", "dog.fill", "cat.fill",
        // Travel
        "suitcase.fill", "map.fill", "globe.americas.fill", "bed.double.fill",
        // Communication
        "phone.fill", "envelope.fill", "bubble.left.fill",
        // Nature & Outdoors
        "leaf.fill", "tree.fill", "mountain.2.fill", "sun.max.fill", "moon.fill",
        // Kids & Family
        "figure.2.and.child.holdinghands", "teddybear.fill", "stroller.fill",
        // Subscriptions & Services
        "play.rectangle.fill", "wrench.fill", "paintbrush.fill", "hammer.fill",
        // Other
        "camera.fill", "sparkles", "star.fill", "tag.fill",
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Preview
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.categoryColors[selectedColorIndex].opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: selectedIcon)
                                .font(.system(size: 24))
                                .foregroundColor(Theme.Colors.categoryColors[selectedColorIndex])
                        }
                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(name.isEmpty ? Color(uiColor: .tertiaryLabel) : Color(uiColor: .label))
                        
                        Text(selectedType.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    .padding(.vertical, 16)
                    
                    VStack(spacing: 0) {
                        FormRow(label: "Name") {
                    TextField("Category Name", text: $name)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.trailing)
                        }
                        
                        Divider().padding(.leading, 16)
                        
                        HStack {
                            Text("Type")
                                .font(.system(size: 15))
                                .foregroundColor(Color(uiColor: .label))
                            Spacer()
                    Picker("Type", selection: $selectedType) {
                                ForEach(CategoryType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .labelsHidden()
                            .tint(Color(uiColor: .secondaryLabel))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        
                        Divider().padding(.leading, 16)
                        
                        FormRow(label: "Note") {
                            TextField("Optional", text: $note)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                        
                        if selectedType == .expense || selectedType == .both {
                            Divider().padding(.leading, 16)
                            
                            FormRow(label: "Monthly Budget") {
                                TextField("No limit", text: $budgetText)
                                    .font(.system(size: 15))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(Color(uiColor: .secondaryLabel))
                            }
                        }
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                    
                    // Icon
                    PickerSection(title: "Icon") {
                        let visibleIcons = showAllIcons ? categoryIcons : Array(categoryIcons.prefix(24))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(visibleIcons, id: \.self) { icon in
                            IconPickerItem(
                                icon: icon,
                                color: Theme.Colors.categoryColors[selectedColorIndex],
                                isSelected: selectedIcon == icon,
                                    action: { selectedIcon = icon; Haptics.selection() }
                                )
                            }
                        }
                        
                        if categoryIcons.count > 24 {
                            Button {
                                withAnimation(.snappy) { showAllIcons.toggle() }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(showAllIcons ? "Show Less" : "Show More")
                                        .font(.system(size: 13, weight: .medium))
                                    Image(systemName: showAllIcons ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(Theme.Colors.primary)
                                .padding(.top, 6)
                            }
                        }
                    }
                    
                    // Color
                    PickerSection(title: "Color") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                        ForEach(0..<Theme.Colors.categoryColors.count, id: \.self) { index in
                            ColorPickerItem(
                                color: Theme.Colors.categoryColors[index],
                                isSelected: selectedColorIndex == index,
                                    action: { selectedColorIndex = index; Haptics.selection() }
                            )
                        }
                    }
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
        let budget = Double(budgetText.replacingOccurrences(of: ",", with: "."))
        let category = Category(
            name: name, icon: selectedIcon, color: colorHex,
            type: selectedType, budget: budget,
            sortOrder: viewModel.categories.count,
            note: note.isEmpty ? nil : note
        )
        viewModel.addCategory(category)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Edit Category View
struct EditCategoryView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    let category: Category
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColorIndex: Int
    @State private var note: String
    @State private var budgetText: String
    @State private var showAllIcons = false
    
    private let categoryIcons = [
        // Food & Dining
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "mug.fill", "carrot.fill", "birthday.cake.fill",
        // Shopping & Fashion
        "cart.fill", "basket.fill", "bag.fill", "storefront.fill", "shippingbox.fill", "gift.fill",
        "tshirt.fill", "shoe.fill", "eyeglasses", "crown.fill",
        // Transport
        "car.fill", "bus.fill", "tram.fill", "bicycle", "airplane", "fuelpump.fill",
        // Entertainment
        "film.fill", "tv.fill", "gamecontroller.fill", "music.note", "ticket.fill", "theatermasks.fill",
        // Health & Fitness & Body
        "heart.fill", "cross.fill", "pills.fill", "stethoscope", "dumbbell.fill", "figure.run",
        "comb.fill", "scissors", "figure.stand", "face.smiling.fill",
        // Home & Utilities
        "house.fill", "bolt.fill", "drop.fill", "flame.fill", "wifi", "washer.fill",
        // Work
        "briefcase.fill", "laptopcomputer", "desktopcomputer", "printer.fill", "keyboard.fill", "doc.fill",
        // Education
        "graduationcap.fill", "book.fill", "pencil", "backpack.fill", "books.vertical.fill", "brain.fill",
        // Finance
        "dollarsign.circle.fill", "chart.line.uptrend.xyaxis", "banknote.fill", "percent", "building.columns.fill", "creditcard.fill",
        // Pets
        "pawprint.fill", "dog.fill", "cat.fill",
        // Travel
        "suitcase.fill", "map.fill", "globe.americas.fill", "bed.double.fill",
        // Communication
        "phone.fill", "envelope.fill", "bubble.left.fill",
        // Nature & Outdoors
        "leaf.fill", "tree.fill", "mountain.2.fill", "sun.max.fill", "moon.fill",
        // Kids & Family
        "figure.2.and.child.holdinghands", "teddybear.fill", "stroller.fill",
        // Subscriptions & Services
        "play.rectangle.fill", "wrench.fill", "paintbrush.fill", "hammer.fill",
        // Other
        "camera.fill", "sparkles", "star.fill", "tag.fill",
    ]
    
    init(viewModel: BalanceViewModel, category: Category) {
        self.viewModel = viewModel
        self.category = category
        _name = State(initialValue: category.name)
        _selectedIcon = State(initialValue: category.icon)
        _note = State(initialValue: category.note ?? "")
        _budgetText = State(initialValue: category.budget != nil ? String(format: "%.0f", category.budget!) : "")
        
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
        ScrollView {
            VStack(spacing: 16) {
                // Preview
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.categoryColors[selectedColorIndex].opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: selectedIcon)
                            .font(.system(size: 24))
                            .foregroundColor(Theme.Colors.categoryColors[selectedColorIndex])
                    }
                    Text(name.isEmpty ? "Category Name" : name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(name.isEmpty ? Color(uiColor: .tertiaryLabel) : Color(uiColor: .label))
                    
                    Text(category.type.rawValue)
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                .padding(.vertical, 16)
                
                // Details
                VStack(spacing: 0) {
                    FormRow(label: "Name") {
                TextField("Category Name", text: $name)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Divider().padding(.leading, 16)
                    
                    FormRow(label: "Note") {
                        TextField("Optional", text: $note)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    
                    if category.type == .expense || category.type == .both {
                        Divider().padding(.leading, 16)
                        
                        FormRow(label: "Monthly Budget") {
                            TextField("No limit", text: $budgetText)
                                .font(.system(size: 15))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(14)
                .padding(.horizontal, 16)
                
                // Icon
                PickerSection(title: "Icon") {
                    let visibleIcons = showAllIcons ? categoryIcons : Array(categoryIcons.prefix(24))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(visibleIcons, id: \.self) { icon in
                        IconPickerItem(
                            icon: icon,
                            color: Theme.Colors.categoryColors[selectedColorIndex],
                            isSelected: selectedIcon == icon,
                                action: { selectedIcon = icon; Haptics.selection() }
                            )
                        }
                    }
                    
                    if categoryIcons.count > 24 {
                        Button {
                            withAnimation(.snappy) { showAllIcons.toggle() }
                        } label: {
                            HStack(spacing: 4) {
                                Text(showAllIcons ? "Show Less" : "Show More")
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: showAllIcons ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.top, 6)
                        }
                    }
                }
                
                // Color
                PickerSection(title: "Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                    ForEach(0..<Theme.Colors.categoryColors.count, id: \.self) { index in
                        ColorPickerItem(
                            color: Theme.Colors.categoryColors[index],
                            isSelected: selectedColorIndex == index,
                                action: { selectedColorIndex = index; Haptics.selection() }
                        )
                    }
                }
            }
            
            if !category.isSystem {
                    Button(role: .destructive, action: {
                        viewModel.deleteCategory(category)
                        dismiss()
                    }) {
                        Text("Delete Category")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
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
        updated.budget = Double(budgetText.replacingOccurrences(of: ",", with: "."))
        viewModel.updateCategory(updated)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Edit Account View
struct EditAccountView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    let account: Account
    
    @State private var name: String
    @State private var selectedType: AccountType
    @State private var selectedIcon: String
    @State private var selectedColorIndex: Int
    @State private var note: String
    
    private let accountIcons = [
        "building.columns.fill", "banknote.fill", "creditcard.fill", "wallet.pass.fill",
        "dollarsign.circle.fill", "lock.fill", "briefcase.fill", "bag.fill",
        "chart.line.uptrend.xyaxis", "chart.bar.fill", "iphone", "globe",
        "bitcoinsign.circle.fill", "eurosign.circle.fill", "sterlingsign.circle.fill",
        "yensign.circle.fill", "pesosign.circle.fill", "indianrupeesign.circle.fill",
        "coloncurrencysign.circle.fill", "francsign.circle.fill",
        "house.fill", "car.fill", "star.fill", "heart.fill",
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
        ScrollView {
            VStack(spacing: 16) {
                // Preview
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.categoryColors[selectedColorIndex].opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: selectedIcon)
                            .font(.system(size: 24))
                            .foregroundColor(Theme.Colors.categoryColors[selectedColorIndex])
                    }
                    Text(name.isEmpty ? "Account Name" : name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(name.isEmpty ? Color(uiColor: .tertiaryLabel) : Color(uiColor: .label))
                    
                    Text(selectedType.rawValue)
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                .padding(.vertical, 16)
                
                // Details
                VStack(spacing: 0) {
                    FormRow(label: "Name") {
                TextField("Account Name", text: $name)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Divider().padding(.leading, 16)
                    
                    HStack {
                        Text("Type")
                            .font(.system(size: 15))
                            .foregroundColor(Color(uiColor: .label))
                        Spacer()
                Picker("Type", selection: $selectedType) {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                        .labelsHidden()
                        .tint(Color(uiColor: .secondaryLabel))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    
                    Divider().padding(.leading, 16)
                    
                    FormRow(label: "Note") {
                        TextField("Optional", text: $note)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(14)
                .padding(.horizontal, 16)
                
                PickerSection(title: "Icon") {
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
            }
            
                // Color
                PickerSection(title: "Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                    ForEach(0..<Theme.Colors.categoryColors.count, id: \.self) { index in
                        ColorPickerItem(
                            color: Theme.Colors.categoryColors[index],
                            isSelected: selectedColorIndex == index,
                                action: { selectedColorIndex = index; Haptics.selection() }
                        )
                    }
                }
            }
            
            if viewModel.accounts.count > 1 {
                    Button(role: .destructive, action: {
                        viewModel.deleteAccount(account)
                        dismiss()
                    }) {
                        Text("Delete Account")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
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

// MARK: - Reusable Components

struct FormRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Color(uiColor: .label))
            Spacer()
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct PickerSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .padding(.horizontal, 20)
            
            content
                .padding(12)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(14)
                .padding(.horizontal, 16)
        }
    }
}

struct IconPickerItem: View {
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? color : color.opacity(0.12))
                    .frame(width: 42, height: 42)
                
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(isSelected ? .white : color)
            }
        }
    }
}

struct ColorPickerItem: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color(uiColor: .label), lineWidth: isSelected ? 2.5 : 0)
                        .padding(isSelected ? -3 : 0)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isSelected ? 1 : 0)
                )
        }
    }
}

// MARK: - Empty State View (legacy compatibility)
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        WalletEmptyState(icon: icon, title: title, message: message)
    }
}

// MARK: - Metric Row (legacy compatibility)
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
                .foregroundColor(Color(uiColor: .label))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Total Balance Card (legacy compatibility)
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
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
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

#Preview {
    NavigationStack {
        WalletView(viewModel: BalanceViewModel())
    }
}
