import SwiftUI
import Charts

// MARK: - Category Detail View
/// Detailed view for a single category with trends and transactions
struct CategoryDetailView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let category: Category
    
    @State private var selectedTimeRange: TimeRange = .monthly
    
    private var stats: CategoryStat {
        viewModel.categoryStats(for: category, in: selectedTimeRange)
    }
    
    private var budgetStatus: BudgetStatus? {
        viewModel.budgetStatus(for: category)
    }
    
    private var categoryTransactions: [Transaction] {
        viewModel.transactions(in: selectedTimeRange)
            .filter { $0.categoryId == category.id }
            .sorted { $0.date > $1.date }
    }
    
    private var monthlyAverage: Double {
        viewModel.monthlyAverage(for: category)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.lg) {
                // Header Card
                categoryHeaderCard
                
                // Time Selector
                TimeScopeSelector(selected: $selectedTimeRange, showAllOptions: false)
                
                // Stats Card
                statsCard
                
                // Budget Status (if has budget)
                if let status = budgetStatus, category.budget != nil {
                    budgetCard(status: status)
                }
                
                // Trend Chart
                trendChartCard
                
                // Transaction List
                if !categoryTransactions.isEmpty {
                    transactionListSection
                }
                
                // View in History Button
                NavigationLink(destination: NewHistoryView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "clock")
                        Text("View All in History")
                    }
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Card
    private var categoryHeaderCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(category.colorValue.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(category.colorValue)
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(category.name)
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primaryText)
                
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
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
    
    // MARK: - Stats Card
    private var statsCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Total Spent
            VStack(spacing: Theme.Spacing.xxs) {
                Text("Total \(selectedTimeRange.shortTitle)")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Text(formatCurrency(stats.total, currency: viewModel.appState.selectedCurrency))
                    .font(Theme.Typography.balanceAmount)
                    .foregroundColor(category.colorValue)
            }
            
            // Delta
            if let delta = stats.deltaFromPrevious, abs(delta) > 0.01 {
                DeltaIndicator(
                    deltaPercent: delta,
                    comparisonLabel: "vs last \(selectedTimeRange.shortTitle.lowercased())",
                    invertColors: category.type == .expense
                )
            }
            
            Divider()
            
            // Stats Row
            HStack {
                // Transactions
                VStack(spacing: Theme.Spacing.xxs) {
                    Text("\(stats.transactionCount)")
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.primaryText)
                    Text("Transactions")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                
                // Percent of Total
                VStack(spacing: Theme.Spacing.xxs) {
                    Text(String(format: "%.0f%%", stats.percentOfTotal * 100))
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.primaryText)
                    Text("of Total")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                
                // Average
                VStack(spacing: Theme.Spacing.xxs) {
                    Text(formatCurrency(stats.averageTransaction, currency: viewModel.appState.selectedCurrency))
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    Text("Avg/Tx")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Monthly Average
            if monthlyAverage > 0 {
                Divider()
                
                HStack {
                    Text("Monthly Average:")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text(formatCurrency(monthlyAverage, currency: viewModel.appState.selectedCurrency))
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
    
    // MARK: - Budget Card
    private func budgetCard(status: BudgetStatus) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Budget")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
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
            
            // Progress
            let budget = category.budget ?? 0
            let spent = viewModel.spendingForCategory(category)
            let progress = budget > 0 ? min(spent / budget, 1.5) : 0
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Colors.secondaryBackground)
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(status.color)
                        .frame(width: geometry.size.width * CGFloat(min(progress, 1.0)), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text(formatCurrency(spent, currency: viewModel.appState.selectedCurrency))
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Spacer()
                
                Text(formatCurrency(budget, currency: viewModel.appState.selectedCurrency))
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
    
    // MARK: - Trend Chart
    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Spending Trend")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            let trendData = getTrendData()
            
            if trendData.isEmpty {
                Text("Not enough data for trend")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
            } else {
                Chart(trendData, id: \.date) { item in
                    BarMark(
                        x: .value("Period", item.label),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(category.colorValue)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 150)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
    
    private func getTrendData() -> [(date: Date, label: String, amount: Double)] {
        let calendar = Calendar.current
        var data: [(date: Date, label: String, amount: Double)] = []
        let periods = selectedTimeRange == .yearly ? 6 : 4
        
        for i in 0..<periods {
            guard let periodDate = calendar.date(byAdding: selectedTimeRange.calendarComponent, value: -i, to: Date()) else { continue }
            
            let transactions = viewModel.transactions(in: selectedTimeRange, referenceDate: periodDate)
                .filter { $0.categoryId == category.id }
            let total = transactions.reduce(0) { $0 + $1.amount }
            
            let label: String
            switch selectedTimeRange {
            case .daily:
                let formatter = DateFormatter()
                formatter.dateFormat = "E"
                label = formatter.string(from: periodDate)
            case .weekly:
                label = "W\(calendar.component(.weekOfMonth, from: periodDate))"
            case .monthly:
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                label = formatter.string(from: periodDate)
            case .yearly:
                label = "\(calendar.component(.year, from: periodDate))"
            }
            
            data.append((date: periodDate, label: label, amount: total))
        }
        
        return data.reversed()
    }
    
    // MARK: - Transaction List
    private var transactionListSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Recent Transactions")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            VStack(spacing: 0) {
                ForEach(categoryTransactions.prefix(10)) { transaction in
                    CategoryTransactionRow(
                        transaction: transaction,
                        account: viewModel.getAccount(by: transaction.accountId),
                        category: category,
                        currency: viewModel.appState.selectedCurrency
                    )
                    
                    if transaction.id != categoryTransactions.prefix(10).last?.id {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }
}

// MARK: - Category Transaction Row
struct CategoryTransactionRow: View {
    let transaction: Transaction
    let account: Account?
    let category: Category
    let currency: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(category.colorValue.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(category.colorValue)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title.isEmpty ? category.name : transaction.title)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
                    .lineLimit(1)
                
                Text(account?.name ?? "")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            // Amount and date
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount)
                    .font(Theme.Typography.headline)
                    .foregroundColor(transaction.type == .expense ? Theme.Colors.expense : Theme.Colors.income)
                
                Text(formatDate(transaction.date))
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
        }
        .padding(Theme.Spacing.sm)
    }
    
    private var formatAmount: String {
        let prefix = transaction.type == .income ? "+" : "-"
        return "\(prefix)\(formatCurrency(transaction.amount, currency: currency))"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        CategoryDetailView(
            viewModel: BalanceViewModel(),
            category: Category(
                name: "Food & Dining",
                icon: "fork.knife",
                color: "#FF9500",
                type: .expense,
                budget: 500
            )
        )
    }
}
