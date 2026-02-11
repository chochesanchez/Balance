import SwiftUI
import Charts

// MARK: - Home View
struct NewHomeView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var showingRecordSheet = false
    @State private var recordInitialType: TransactionType? = nil
    @State private var balanceHidden = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HomeHeader(viewModel: viewModel)
                
                // 1. Total Balance
                if !balanceHidden {
                    BalanceCard(viewModel: viewModel, isHidden: $balanceHidden)
                } else {
                    BalanceHiddenPill(isHidden: $balanceHidden)
                }
                
                // 2. Quick Actions
                HomeSectionHeader(title: "Quick Actions")
                QuickActionsRow(onAction: { type in
                    recordInitialType = type
                    showingRecordSheet = true
                })
                
                // 3. My Accounts
                AccountsSection(viewModel: viewModel)
                
                // 4. Summary (Day/Week/Month/Year)
                SummaryCard(viewModel: viewModel)
                
                // 5. Calendar
                HomeCalendarSection(viewModel: viewModel)
                
                // 6. Goals (always show)
                GoalsSummarySection(viewModel: viewModel)
                
                // 7. Recurring (always show)
                RecurringSummarySection(viewModel: viewModel)
                
                // 8. Daily Tip
                HomeSectionHeader(title: "Daily Tip")
                DailyTipCard()
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .refreshable { viewModel.checkAndProcessRecurring() }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showingRecordSheet) {
            NavigationStack {
                RecordView(viewModel: viewModel, initialType: recordInitialType)
            }
        }
    }
}

// MARK: - Section Header
struct HomeSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(uiColor: .label))
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Header
struct HomeHeader: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    var body: some View {
        NavigationLink(destination: ProfileDetailView(viewModel: viewModel)) {
            HStack(spacing: 12) {
                ProfileAvatarView(imageData: viewModel.userProfile.profileImageData, size: 40)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Welcome")
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Text(viewModel.userProfile.name.isEmpty ? "Balance" : viewModel.userProfile.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Balance Card
struct BalanceCard: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Binding var isHidden: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Total Balance")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) { isHidden = true }
                    Haptics.light()
                }) {
                    Image(systemName: "eye")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
            
            AnimatedBalanceText(
                value: viewModel.totalBalance,
                currency: viewModel.appState.selectedCurrency,
                font: .system(size: 36, weight: .bold, design: .rounded),
                color: Color(uiColor: .label)
            )
            
            HStack(spacing: 12) {
                MiniStatView(
                    icon: "arrow.down",
                    label: "Income",
                    value: viewModel.currentRangeIncome,
                    color: Theme.Colors.income,
                    currency: viewModel.appState.selectedCurrency
                )
                
                MiniStatView(
                    icon: "arrow.up",
                    label: "Expenses",
                    value: viewModel.currentRangeExpenses,
                    color: Theme.Colors.expense,
                    currency: viewModel.appState.selectedCurrency
                )
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

struct BalanceHiddenPill: View {
    @Binding var isHidden: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) { isHidden = false }
            Haptics.light()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "eye.slash")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                
                Text("Balance hidden")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                
                Spacer()
                
                Text("Tap to show")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(14)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

struct MiniStatView: View {
    let icon: String
    let label: String
    let value: Double
    let color: Color
    let currency: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .padding(6)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                
                Text(formatCompact(value))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(uiColor: .label))
                    .contentTransition(.numericText(value: value))
                    .animation(.snappy, value: value)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatCompact(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Quick Actions
struct QuickActionsRow: View {
    let onAction: (TransactionType) -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            QuickActionButton(icon: "arrow.down", label: "Income", color: Theme.Colors.income) {
                onAction(.income)
            }
            QuickActionButton(icon: "arrow.up", label: "Expense", color: Theme.Colors.expense) {
                onAction(.expense)
            }
            QuickActionButton(icon: "arrow.left.arrow.right", label: "Transfer", color: Theme.Colors.transfer) {
                onAction(.transfer)
            }
            QuickActionButton(icon: "repeat", label: "Recurring", color: Color(hex: "5856D6")) {
                onAction(.expense)
            }
        }
        .padding(14)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            Haptics.light()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 42, height: 42)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(uiColor: .label))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

// MARK: - Summary Card (Day / Week / Month / Year)
enum SummaryScope: String, CaseIterable {
    case day = "Today"
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"
}

struct SummaryCard: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var scope: SummaryScope = .week
    @State private var showScopePicker = false
    
    private var dateInterval: DateInterval {
        let cal = Calendar.current
        switch scope {
        case .day: return cal.dateInterval(of: .day, for: Date()) ?? DateInterval()
        case .week: return cal.dateInterval(of: .weekOfYear, for: Date()) ?? DateInterval()
        case .month: return cal.dateInterval(of: .month, for: Date()) ?? DateInterval()
        case .year: return cal.dateInterval(of: .year, for: Date()) ?? DateInterval()
        }
    }
    
    private var scopeTransactions: [Transaction] {
        viewModel.transactions.filter { $0.date >= dateInterval.start && $0.date < dateInterval.end }
    }
    
    private var income: Double {
        scopeTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var expenses: Double {
        scopeTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var net: Double { income - expenses }
    
    private var dateLabel: String {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        switch scope {
        case .day:
            df.dateFormat = "EEEE, MMM d"
            return df.string(from: Date())
        case .week:
            return "\(df.string(from: dateInterval.start)) - \(df.string(from: dateInterval.end.addingTimeInterval(-1)))"
        case .month:
            df.dateFormat = "MMMM yyyy"
            return df.string(from: Date())
        case .year:
            df.dateFormat = "yyyy"
            return df.string(from: Date())
        }
    }
    
    var body: some View {
        VStack(spacing: 14) {
            // Header with scope toggle
            HStack {
                Text("Summary")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                Spacer()
                
                Menu {
                    ForEach(SummaryScope.allCases, id: \.self) { s in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) { scope = s }
                        }) {
                            HStack {
                                Text(s.rawValue)
                                if scope == s { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(scope.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
            
            Text(dateLabel)
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 0) {
                SummaryStatColumn(label: "Income", value: income, color: Theme.Colors.income, currency: viewModel.appState.selectedCurrency)
                
                Rectangle().fill(Color(uiColor: .separator)).frame(width: 0.5, height: 36)
                
                SummaryStatColumn(label: "Expenses", value: expenses, color: Theme.Colors.expense, currency: viewModel.appState.selectedCurrency)
                
                Rectangle().fill(Color(uiColor: .separator)).frame(width: 0.5, height: 36)
                
                SummaryStatColumn(label: "Savings", value: net, color: net >= 0 ? Theme.Colors.income : Theme.Colors.expense, currency: viewModel.appState.selectedCurrency)
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

struct SummaryStatColumn: View {
    let label: String
    let value: Double
    let color: Color
    let currency: String
    
    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            
            Text(formatShort(value))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .contentTransition(.numericText(value: value))
                .animation(.snappy, value: value)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatShort(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Calendar Section
struct HomeCalendarSection: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var selectedDate = Date()
    
    private var calendar: Calendar { Calendar.current }
    
    private var monthDays: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedDate),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstOfMonth) }
    }
    
    private var firstWeekday: Int {
        guard let first = monthDays.first else { return 0 }
        return (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
    }
    
    private func transactionsFor(_ date: Date) -> [Transaction] {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return viewModel.transactions.filter { $0.date >= start && $0.date < end }
    }
    
    private var monthLabel: String {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df.string(from: selectedDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation { selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    
                    Text(monthLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Button(action: {
                        withAnimation { selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
            }
            
            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                        .frame(height: 16)
                }
                
                // Empty cells before first day
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Text("").frame(height: 32)
                }
                
                // Days
                ForEach(monthDays, id: \.self) { date in
                    let txs = transactionsFor(date)
                    let isToday = calendar.isDateInToday(date)
                    let hasIncome = txs.contains { $0.type == .income }
                    let hasExpense = txs.contains { $0.type == .expense }
                    
                    VStack(spacing: 2) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 13, weight: isToday ? .bold : .regular))
                            .foregroundColor(isToday ? .white : Color(uiColor: .label))
                            .frame(width: 28, height: 28)
                            .background(isToday ? Theme.Colors.primary : Color.clear)
                            .clipShape(Circle())
                        
                        HStack(spacing: 2) {
                            if hasIncome {
                                Circle().fill(Theme.Colors.income).frame(width: 4, height: 4)
                            }
                            if hasExpense {
                                Circle().fill(Theme.Colors.expense).frame(width: 4, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                    .frame(height: 36)
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Accounts Section
struct AccountsSection: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "My Accounts") {
                // Navigation handled by NavigationLink below
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.accounts) { account in
                        AccountCard(
                            account: account,
                            balance: viewModel.balanceForAccount(account),
                            currency: viewModel.appState.selectedCurrency
                        )
                    }
                    
                    NavigationLink(destination: WalletView(viewModel: viewModel)) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                                .frame(width: 40, height: 40)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .clipShape(Circle())
                            
                            Text("$0.00")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.clear)
                            
                            Text("Add")
                                .font(.system(size: 11))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                        .frame(width: 100)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(14)
                    }
                }
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

struct AccountCard: View {
    let account: Account
    let balance: Double
    let currency: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: account.icon)
                .font(.system(size: 18))
                .foregroundColor(account.colorValue)
                .frame(width: 40, height: 40)
                .background(account.colorValue.opacity(0.12))
                .clipShape(Circle())
            
            Text(formatCurrency(balance, currency: currency))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color(uiColor: .label))
                .lineLimit(1)
            
            Text(account.name)
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .lineLimit(1)
        }
        .frame(width: 100)
        .padding(.vertical, 14)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Goals Summary (always visible)
struct GoalsSummarySection: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    private var activeGoals: [Goal] {
        viewModel.goals.filter { !$0.isCompleted }
    }
    
    private var completedCount: Int {
        viewModel.goals.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Goals")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                Spacer()
                
                NavigationLink(destination: MoreView(viewModel: viewModel)) {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            if activeGoals.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "target")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "FF9500").opacity(0.3))
                    
                    Text("No active goals")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Text("Set savings targets to track your progress")
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 10) {
                    ForEach(activeGoals.prefix(3)) { goal in
                        GoalItemRow(goal: goal, currency: viewModel.appState.selectedCurrency)
                    }
                }
                
                if completedCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.income)
                        Text("\(completedCount) completed")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

struct GoalItemRow: View {
    let goal: Goal
    let currency: String
    
    private var progress: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(1, goal.currentAmount / goal.targetAmount)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: goal.icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: goal.color))
                .frame(width: 34, height: 34)
                .background(Color(hex: goal.color).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(goal.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(uiColor: .label))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: goal.color))
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(uiColor: .tertiarySystemFill))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(Color(hex: goal.color))
                            .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 4)
                    }
                }
                .frame(height: 4)
                
                HStack {
                    Text(formatCurrency(goal.currentAmount, currency: currency))
                        .font(.system(size: 11))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Spacer()
                    
                    Text(formatCurrency(goal.targetAmount, currency: currency))
                        .font(.system(size: 11))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }
        }
    }
}

// MARK: - Recurring Summary (always visible)
struct RecurringSummarySection: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    private var activeRecurring: [RecurringTransaction] {
        viewModel.recurringTransactions.filter { $0.isActive }
    }
    
    private var monthlyTotal: Double {
        activeRecurring.reduce(0) { total, rt in
            let multiplier: Double
            switch rt.frequency {
            case .daily: multiplier = 30
            case .weekly: multiplier = 4.33
            case .biweekly: multiplier = 2.17
            case .monthly: multiplier = 1
            case .quarterly: multiplier = 0.33
            case .yearly: multiplier = 0.083
            }
            return total + (rt.type == .expense ? rt.amount * multiplier : 0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recurring")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                Spacer()
                
                NavigationLink(destination: RecurringView(viewModel: viewModel)) {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            if activeRecurring.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "5856D6").opacity(0.3))
                    
                    Text("No recurring transactions")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Text("Add subscriptions, rent, salary and more")
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "5856D6"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "5856D6").opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly estimate")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        
                        Text(formatCurrency(monthlyTotal, currency: viewModel.appState.selectedCurrency))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(uiColor: .label))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(activeRecurring.count) active")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        
                        if viewModel.overdueRecurring.count > 0 {
                            Text("\(viewModel.overdueRecurring.count) overdue")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(uiColor: .systemRed))
                        } else if viewModel.upcomingRecurring.count > 0 {
                            Text("\(viewModel.upcomingRecurring.count) upcoming")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
                
                VStack(spacing: 0) {
                    ForEach(Array(activeRecurring.prefix(3).enumerated()), id: \.element.id) { index, recurring in
                        RecurringItemRow(
                            recurring: recurring,
                            category: viewModel.getCategory(by: recurring.categoryId),
                            currency: viewModel.appState.selectedCurrency
                        )
                        
                        if index < min(activeRecurring.count, 3) - 1 {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                
                if activeRecurring.count > 3 {
                    NavigationLink(destination: RecurringView(viewModel: viewModel)) {
                        Text("View all \(activeRecurring.count) recurring")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

struct RecurringItemRow: View {
    let recurring: RecurringTransaction
    let category: Category?
    let currency: String
    
    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: recurring.nextDueDate).day ?? 0
    }
    
    private var dueLabel: String {
        if daysUntilDue < 0 { return "Overdue" }
        if daysUntilDue == 0 { return "Due today" }
        if daysUntilDue == 1 { return "Tomorrow" }
        return "In \(daysUntilDue) days"
    }
    
    private var dueColor: Color {
        if daysUntilDue < 0 { return Color(uiColor: .systemRed) }
        if daysUntilDue <= 2 { return Color(hex: "FF9500") }
        return Color(uiColor: .secondaryLabel)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category?.icon ?? recurring.frequency.icon)
                .font(.system(size: 14))
                .foregroundColor(category?.colorValue ?? Color(hex: "5856D6"))
                .frame(width: 34, height: 34)
                .background((category?.colorValue ?? Color(hex: "5856D6")).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 1) {
                Text(recurring.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(uiColor: .label))
                    .lineLimit(1)
                
                Text("\(recurring.frequency.rawValue) \u{2022} \(dueLabel)")
                    .font(.system(size: 11))
                    .foregroundColor(dueColor)
            }
            
            Spacer()
            
            Text(recurring.type == .income ? "+\(formatCurrency(recurring.amount, currency: currency))" : "-\(formatCurrency(recurring.amount, currency: currency))")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(recurring.type == .income ? Theme.Colors.income : Theme.Colors.expense)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Daily Tip
struct DailyTipCard: View {
    private let tips = [
        (icon: "lightbulb.max.fill", title: "50/30/20 Rule", tip: "Try allocating 50% for needs, 30% for wants, and 20% for savings."),
        (icon: "chart.pie.fill", title: "Track Everything", tip: "Small expenses add up! Record every purchase to see where your money goes."),
        (icon: "arrow.up.right.circle.fill", title: "Pay Yourself First", tip: "Set aside savings before spending on anything else."),
        (icon: "calendar", title: "Weekly Reviews", tip: "Check your spending every week to stay on track with your goals."),
        (icon: "creditcard.fill", title: "Avoid Impulse Buys", tip: "Wait 24 hours before making non-essential purchases."),
        (icon: "banknote.fill", title: "Emergency Fund", tip: "Try to save 3-6 months of expenses for unexpected costs."),
        (icon: "arrow.triangle.2.circlepath", title: "Automate Savings", tip: "Set up automatic transfers to your savings account."),
    ]
    
    private var todaysTip: (icon: String, title: String, tip: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return tips[dayOfYear % tips.count]
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: todaysTip.icon)
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "FF9500"))
                .frame(width: 40, height: 40)
                .background(Color(hex: "FF9500").opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text(todaysTip.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                Text(todaysTip.tip)
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Profile Avatar
struct ProfileAvatarView: View {
    let imageData: Data?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(width: size, height: size)
            
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
    }
}

// MARK: - Profile Detail (redirects to full profile in More)
struct ProfileDetailView: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    var body: some View {
        NewProfileView(viewModel: viewModel)
    }
}

// MARK: - Helpers
func formatCurrency(_ amount: Double, currency: String = "USD") -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
}

func formatSignedCurrency(_ amount: Double, currency: String = "USD") -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    let formatted = formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    return amount >= 0 ? "+\(formatted)" : "-\(formatted)"
}

func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}
