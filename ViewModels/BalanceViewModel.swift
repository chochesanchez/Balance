import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - Balance ViewModel
/// Main ViewModel for the Balance app with new architecture

@MainActor
class BalanceViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var accounts: [Account] = []
    @Published var categories: [Category] = []
    @Published var transactions: [Transaction] = []
    @Published var goals: [Goal] = []
    @Published var recurringTransactions: [RecurringTransaction] = []
    @Published var userProfile: UserProfile = UserProfile()
    @Published var appState: AppState = AppState()
    
    // MARK: - Private Properties
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Storage Keys
    private enum Keys {
        static let accounts = "balance_accounts"
        static let categories = "balance_categories"
        static let transactions = "balance_transactions"
        static let goals = "balance_goals"
        static let recurring = "balance_recurring"
        static let userProfile = "balance_userProfile"
        static let appState = "balance_appState"
    }
    
    // MARK: - Initialization
    init() {
        loadAllData()
        setupDefaultsIfNeeded()
        checkAndProcessRecurring()
        requestNotificationPermission()
    }
    
    private func setupDefaultsIfNeeded() {
        // Categories are EMPTY by default - user creates their own!
        // Only add default account if empty
        if accounts.isEmpty {
            accounts = Account.defaultAccounts
            saveAccounts()
        }
    }
    
    // MARK: - Computed Properties
    
    var totalBalance: Double {
        accounts.reduce(0) { total, account in
            total + balanceForAccount(account)
        }
    }
    
    var monthlyIncome: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        
        return transactions
            .filter { $0.date >= startOfMonth && $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthlyExpenses: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        
        return transactions
            .filter { $0.date >= startOfMonth && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthlySavings: Double {
        monthlyIncome - monthlyExpenses
    }
    
    var savingsRate: Double {
        guard monthlyIncome > 0 else { return 0 }
        return (monthlySavings / monthlyIncome) * 100
    }
    
    var expenseCategories: [Category] {
        categories.filter { $0.type == .expense }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var incomeCategories: [Category] {
        categories.filter { $0.type == .income }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var recentTransactions: [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(5))
    }
    
    var hasCompletedOnboarding: Bool {
        appState.hasCompletedOnboarding
    }
    
    var upcomingRecurring: [RecurringTransaction] {
        recurringTransactions
            .filter { $0.isActive && $0.daysUntilDue <= 7 }
            .sorted { $0.nextDueDate < $1.nextDueDate }
    }
    
    var overdueRecurring: [RecurringTransaction] {
        recurringTransactions.filter { $0.isActive && $0.isOverdue }
    }
    
    // MARK: - Account Functions
    
    func balanceForAccount(_ account: Account) -> Double {
        let transactionBalance = transactions.reduce(0.0) { total, transaction in
            var amount = total
            
            // Add income to this account
            if transaction.type == .income && transaction.accountId == account.id {
                amount += transaction.amount
            }
            
            // Subtract expense from this account
            if transaction.type == .expense && transaction.accountId == account.id {
                amount -= transaction.amount
            }
            
            // Handle transfers
            if transaction.type == .transfer {
                if transaction.accountId == account.id {
                    amount -= transaction.amount // Money leaving
                }
                if transaction.toAccountId == account.id {
                    amount += transaction.amount // Money arriving
                }
            }
            
            return amount
        }
        
        return account.initialBalance + transactionBalance
    }
    
    func addAccount(_ account: Account) {
        accounts.append(account)
        saveAccounts()
    }
    
    func updateAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts()
        }
    }
    
    func deleteAccount(_ account: Account) {
        // Don't delete if it's the only account
        guard accounts.count > 1 else { return }
        
        // Move transactions to first available account
        if let defaultAccount = accounts.first(where: { $0.id != account.id }) {
            transactions = transactions.map { transaction in
                var updated = transaction
                if transaction.accountId == account.id {
                    updated.accountId = defaultAccount.id
                }
                if transaction.toAccountId == account.id {
                    updated.toAccountId = defaultAccount.id
                }
                return updated
            }
            saveTransactions()
        }
        
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
    }
    
    func getAccount(by id: UUID) -> Account? {
        accounts.first { $0.id == id }
    }
    
    // MARK: - Category Functions
    
    func addCategory(_ category: Category) {
        categories.append(category)
        saveCategories()
    }
    
    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }
    
    func deleteCategory(_ category: Category) {
        // Don't delete system categories
        guard !category.isSystem else { return }
        
        // Remove category reference from transactions
        transactions = transactions.map { transaction in
            var updated = transaction
            if transaction.categoryId == category.id {
                updated.categoryId = nil
            }
            return updated
        }
        saveTransactions()
        
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    func getCategory(by id: UUID?) -> Category? {
        guard let id = id else { return nil }
        return categories.first { $0.id == id }
    }
    
    func spendingForCategory(_ category: Category, inMonth date: Date = Date()) -> Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? date
        
        return transactions
            .filter { $0.categoryId == category.id && $0.date >= startOfMonth && $0.date < endOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Transaction Functions
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        saveTransactions()
        Haptics.success()
    }
    
    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            saveTransactions()
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        saveTransactions()
    }
    
    func transactionsForAccount(_ account: Account) -> [Transaction] {
        transactions.filter { $0.accountId == account.id || $0.toAccountId == account.id }
            .sorted { $0.date > $1.date }
    }
    
    func transactionsForCategory(_ category: Category) -> [Transaction] {
        transactions.filter { $0.categoryId == category.id }
            .sorted { $0.date > $1.date }
    }
    
    func transactionsForDateRange(from startDate: Date, to endDate: Date) -> [Transaction] {
        transactions.filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date > $1.date }
    }
    
    // MARK: - Recurring Transaction Functions
    
    func addRecurring(_ recurring: RecurringTransaction) {
        recurringTransactions.append(recurring)
        saveRecurring()
        scheduleNotification(for: recurring)
    }
    
    func updateRecurring(_ recurring: RecurringTransaction) {
        if let index = recurringTransactions.firstIndex(where: { $0.id == recurring.id }) {
            recurringTransactions[index] = recurring
            saveRecurring()
            // Reschedule notification
            cancelNotification(for: recurring)
            if recurring.isActive {
                scheduleNotification(for: recurring)
            }
        }
    }
    
    func deleteRecurring(_ recurring: RecurringTransaction) {
        cancelNotification(for: recurring)
        recurringTransactions.removeAll { $0.id == recurring.id }
        saveRecurring()
    }
    
    func processRecurring(_ recurring: RecurringTransaction) {
        // Create the transaction
        let transaction = Transaction(
            amount: recurring.amount,
            type: recurring.type,
            accountId: recurring.accountId,
            categoryId: recurring.categoryId,
            title: recurring.title,
            note: recurring.note,
            date: recurring.nextDueDate,
            recurringId: recurring.id
        )
        addTransaction(transaction)
        
        // Update recurring to next due date
        var updated = recurring
        updated.lastProcessedDate = Date()
        updated.nextDueDate = recurring.frequency.nextDate(from: recurring.nextDueDate)
        
        // Check if should deactivate (past end date)
        if let endDate = updated.endDate, updated.nextDueDate > endDate {
            updated.isActive = false
        }
        
        updateRecurring(updated)
    }
    
    func checkAndProcessRecurring() {
        // Auto-process any overdue recurring transactions
        for recurring in recurringTransactions where recurring.isActive && recurring.isOverdue {
            processRecurring(recurring)
        }
    }
    
    // MARK: - Notification Functions
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.appState.notificationsEnabled = granted
            }
        }
    }
    
    func scheduleNotification(for recurring: RecurringTransaction) {
        guard appState.notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming \(recurring.type.rawValue)"
        content.body = "\(recurring.title): \(formatCurrencyForNotification(recurring.amount)) is due soon"
        content.sound = .default
        
        // Schedule notification for X days before due date
        let notifyDate = Calendar.current.date(byAdding: .day, value: -recurring.notifyDaysBefore, to: recurring.nextDueDate) ?? recurring.nextDueDate
        
        // Only schedule if notification date is in the future
        guard notifyDate > Date() else { return }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notifyDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: recurring.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(for recurring: RecurringTransaction) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [recurring.id.uuidString])
    }
    
    private func formatCurrencyForNotification(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = appState.selectedCurrency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    // MARK: - Goal Functions
    
    func addGoal(_ goal: Goal) {
        goals.append(goal)
        saveGoals()
    }
    
    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals()
        }
    }
    
    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        saveGoals()
    }
    
    func contributeToGoal(_ goal: Goal, amount: Double) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            var updated = goal
            updated.currentAmount += amount
            if updated.currentAmount >= updated.targetAmount {
                updated.isCompleted = true
            }
            goals[index] = updated
            saveGoals()
        }
    }
    
    // MARK: - User Profile Functions
    
    func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        saveUserProfile()
    }
    
    func updateProfileImage(_ imageData: Data?) {
        userProfile.profileImageData = imageData
        saveUserProfile()
    }
    
    // MARK: - Onboarding Functions
    
    func completeOnboarding() {
        appState.hasCompletedOnboarding = true
        saveAppState()
    }
    
    func resetOnboarding() {
        appState.hasCompletedOnboarding = false
        saveAppState()
    }
    
    // MARK: - Analytics
    
    func spendingByCategory(for month: Date = Date()) -> [(category: Category, amount: Double, percentage: Double)] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? month
        
        let monthExpenses = transactions.filter {
            $0.type == .expense && $0.date >= startOfMonth && $0.date < endOfMonth
        }
        
        let totalExpenses = monthExpenses.reduce(0) { $0 + $1.amount }
        
        var categorySpending: [UUID: Double] = [:]
        for transaction in monthExpenses {
            if let categoryId = transaction.categoryId {
                categorySpending[categoryId, default: 0] += transaction.amount
            }
        }
        
        return categorySpending.compactMap { (categoryId, amount) in
            guard let category = getCategory(by: categoryId) else { return nil }
            let percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0
            return (category: category, amount: amount, percentage: percentage)
        }.sorted { $0.amount > $1.amount }
    }
    
    func monthOverMonthComparison(months: Int = 6) -> [(month: Date, income: Double, expenses: Double)] {
        let calendar = Calendar.current
        var result: [(month: Date, income: Double, expenses: Double)] = []
        
        for i in 0..<months {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) else { continue }
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) ?? monthDate
            guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { continue }
            
            let monthTransactions = transactions.filter { $0.date >= startOfMonth && $0.date < endOfMonth }
            
            let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expenses = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            result.append((month: startOfMonth, income: income, expenses: expenses))
        }
        
        return result.reversed()
    }
    
    // MARK: - Time Range Filtering
    
    /// Get transactions within the selected time range
    func transactions(in range: TimeRange, referenceDate: Date = Date()) -> [Transaction] {
        guard let interval = range.dateInterval(for: referenceDate) else { return transactions }
        return transactions.filter { $0.date >= interval.start && $0.date < interval.end }
    }
    
    /// Get transactions from the previous period
    func previousPeriodTransactions(for range: TimeRange, referenceDate: Date = Date()) -> [Transaction] {
        guard let interval = range.previousDateInterval(for: referenceDate) else { return [] }
        return transactions.filter { $0.date >= interval.start && $0.date < interval.end }
    }
    
    /// Current period transactions based on app state
    var currentRangeTransactions: [Transaction] {
        transactions(in: appState.preferredTimeRange)
    }
    
    /// Previous period transactions based on app state
    var previousRangeTransactions: [Transaction] {
        previousPeriodTransactions(for: appState.preferredTimeRange)
    }
    
    // MARK: - Time-Aware Metrics
    
    /// Income for current selected time range
    var currentRangeIncome: Double {
        currentRangeTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Expenses for current selected time range
    var currentRangeExpenses: Double {
        currentRangeTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Net savings for current range
    var currentRangeNet: Double {
        currentRangeIncome - currentRangeExpenses
    }
    
    /// Savings rate for current range (as decimal, e.g. 0.25 for 25%)
    var currentRangeSavingsRate: Double {
        guard currentRangeIncome > 0 else { return 0 }
        return max(0, currentRangeNet / currentRangeIncome)
    }
    
    /// Previous period income
    var previousRangeIncome: Double {
        previousRangeTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Previous period expenses
    var previousRangeExpenses: Double {
        previousRangeTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Delta in expenses vs previous period (positive = spending more)
    var expenseDelta: Double {
        currentRangeExpenses - previousRangeExpenses
    }
    
    /// Percentage change in expenses vs previous period
    var expenseDeltaPercent: Double {
        guard previousRangeExpenses > 0 else { return 0 }
        return expenseDelta / previousRangeExpenses
    }
    
    /// Delta in income vs previous period
    var incomeDelta: Double {
        currentRangeIncome - previousRangeIncome
    }
    
    /// Percentage change in income vs previous period
    var incomeDeltaPercent: Double {
        guard previousRangeIncome > 0 else { return 0 }
        return incomeDelta / previousRangeIncome
    }
    
    // MARK: - Category Statistics
    
    /// Get detailed stats for all expense categories in current range
    var topCategoryStats: [CategoryStat] {
        let current = currentRangeTransactions.filter { $0.type == .expense }
        let previous = previousRangeTransactions.filter { $0.type == .expense }
        
        let totalExpenses = current.reduce(0) { $0 + $1.amount }
        
        let groupedCurrent = Dictionary(grouping: current, by: { $0.categoryId })
        let groupedPrevious = Dictionary(grouping: previous, by: { $0.categoryId })
        
        return categories.filter { $0.type == .expense }.compactMap { category in
            let currentTx = groupedCurrent[category.id] ?? []
            let previousTx = groupedPrevious[category.id] ?? []
            
            let currentTotal = currentTx.reduce(0) { $0 + $1.amount }
            guard currentTotal > 0 else { return nil }
            
            let previousTotal = previousTx.reduce(0) { $0 + $1.amount }
            
            let deltaPercent: Double?
            if previousTotal > 0 {
                deltaPercent = (currentTotal - previousTotal) / previousTotal
            } else {
                deltaPercent = nil
            }
            
            let percentOfTotal = totalExpenses > 0 ? currentTotal / totalExpenses : 0
            let avgTransaction = currentTx.count > 0 ? currentTotal / Double(currentTx.count) : 0
            
            return CategoryStat(
                category: category,
                total: currentTotal,
                transactionCount: currentTx.count,
                percentOfTotal: percentOfTotal,
                deltaFromPrevious: deltaPercent,
                averageTransaction: avgTransaction
            )
        }.sorted { $0.total > $1.total }
    }
    
    /// Get stats for a specific category
    func categoryStats(for category: Category, in range: TimeRange) -> CategoryStat {
        let current = transactions(in: range).filter { $0.categoryId == category.id }
        let previous = previousPeriodTransactions(for: range).filter { $0.categoryId == category.id }
        
        let totalExpenses = transactions(in: range).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        
        let currentTotal = current.reduce(0) { $0 + $1.amount }
        let previousTotal = previous.reduce(0) { $0 + $1.amount }
        
        let deltaPercent: Double?
        if previousTotal > 0 {
            deltaPercent = (currentTotal - previousTotal) / previousTotal
        } else {
            deltaPercent = nil
        }
        
        let percentOfTotal = totalExpenses > 0 ? currentTotal / totalExpenses : 0
        let avgTransaction = current.count > 0 ? currentTotal / Double(current.count) : 0
        
        return CategoryStat(
            category: category,
            total: currentTotal,
            transactionCount: current.count,
            percentOfTotal: percentOfTotal,
            deltaFromPrevious: deltaPercent,
            averageTransaction: avgTransaction
        )
    }
    
    /// Calculate average monthly spending for a category (over last 3 months)
    func monthlyAverage(for category: Category) -> Double {
        var total: Double = 0
        var monthsWithData = 0
        let calendar = Calendar.current
        
        for i in 0..<3 {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) {
                let spending = spendingForCategory(category, inMonth: monthDate)
                if spending > 0 {
                    total += spending
                    monthsWithData += 1
                }
            }
        }
        
        return monthsWithData > 0 ? total / Double(monthsWithData) : 0
    }
    
    // MARK: - Insight Engine
    
    /// Generate smart insights based on current financial data
    var homeInsights: [Insight] {
        var insights: [Insight] = []
        let timeLabel = appState.preferredTimeRange.shortTitle.lowercased()
        
        // 1. Savings Rate Insight
        if currentRangeIncome > 0 {
            let rate = currentRangeSavingsRate
            let percent = Int(rate * 100)
            
            if rate >= 0.20 {
                insights.append(Insight(
                    type: .savings,
                    title: "Great savings! 🎉",
                    message: "You're saving \(percent)% of your income this \(timeLabel). Keep it up!",
                    severity: .positive
                ))
            } else if rate > 0 {
                insights.append(Insight(
                    type: .savings,
                    title: "Room to grow",
                    message: "You're saving \(percent)% this \(timeLabel). Aim for 20% as a healthy target.",
                    severity: .neutral
                ))
            } else if rate < 0 {
                insights.append(Insight(
                    type: .spending,
                    title: "Spending exceeds income",
                    message: "You've spent more than you earned this \(timeLabel). Review your expenses.",
                    severity: .warning
                ))
            }
        }
        
        // 2. Expense Comparison Insight
        if previousRangeExpenses > 0 {
            let deltaP = Int(abs(expenseDeltaPercent) * 100)
            
            if expenseDeltaPercent > 0.15 {
                insights.append(Insight(
                    type: .spending,
                    title: "Spending is up",
                    message: "Your expenses are \(deltaP)% higher than last \(timeLabel).",
                    severity: .warning
                ))
            } else if expenseDeltaPercent < -0.15 {
                insights.append(Insight(
                    type: .spending,
                    title: "Nice! Spending is down",
                    message: "You've reduced expenses by \(deltaP)% from last \(timeLabel).",
                    severity: .positive
                ))
            }
        }
        
        // 3. Top Category Alert
        if let topCategory = topCategoryStats.first,
           let delta = topCategory.deltaFromPrevious,
           delta > 0.20 {
            let p = Int(delta * 100)
            insights.append(Insight(
                type: .category,
                title: "\(topCategory.category.name) trending up",
                message: "You're spending \(p)% more on \(topCategory.category.name) than usual.",
                severity: .warning,
                relatedCategoryId: topCategory.category.id
            ))
        }
        
        // 4. Income Increase Celebration
        if previousRangeIncome > 0 && incomeDeltaPercent > 0.10 {
            let p = Int(incomeDeltaPercent * 100)
            insights.append(Insight(
                type: .savings,
                title: "Income boost! 💪",
                message: "Your income is up \(p)% from last \(timeLabel).",
                severity: .positive
            ))
        }
        
        // 5. Upcoming Bills Warning
        let upcomingTotal = upcomingRecurring.reduce(0) { $0 + $1.amount }
        if upcomingRecurring.count > 0 && upcomingTotal > 0 {
            insights.append(Insight(
                type: .habit,
                title: "\(upcomingRecurring.count) bills coming up",
                message: "About \(formatCurrencyCompact(upcomingTotal)) due in the next 7 days.",
                severity: .neutral,
                icon: "calendar.badge.clock"
            ))
        }
        
        // 6. No Activity Today (weekday only)
        let todayTransactions = transactions.filter { Calendar.current.isDateInToday($0.date) }
        if todayTransactions.isEmpty && !Calendar.current.isDateInWeekend(Date()) && transactions.count > 5 {
            insights.append(Insight(
                type: .tip,
                title: "Nothing recorded today",
                message: "Don't forget to track your expenses!",
                severity: .neutral,
                icon: "pencil.and.list.clipboard"
            ))
        }
        
        // Limit to 3 insights for UI cleanliness
        return Array(insights.prefix(3))
    }
    
    /// Format currency compactly for insights
    private func formatCurrencyCompact(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = appState.selectedCurrency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
    
    // MARK: - Greeting
    
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        else if hour < 17 { return "Good afternoon" }
        else { return "Good evening" }
    }
    
    // MARK: - Time Range Management
    
    func setTimeRange(_ range: TimeRange) {
        appState.preferredTimeRange = range
        saveAppState()
    }
    
    // MARK: - Goal Status
    
    func status(for goal: Goal) -> GoalStatus {
        if goal.isCompleted { return .completed }
        guard let deadline = goal.deadline else { return .noDeadline }
        
        let now = Date()
        let totalDays = deadline.timeIntervalSince(goal.createdAt)
        let elapsedDays = now.timeIntervalSince(goal.createdAt)
        
        guard totalDays > 0 else { return .noDeadline }
        
        let expectedProgress = elapsedDays / totalDays
        let actualProgress = goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0
        
        // If actual progress is within 10% of expected, consider on track
        if actualProgress >= expectedProgress - 0.1 {
            return .onTrack
        } else {
            return .behind
        }
    }
    
    // MARK: - Budget Status
    
    func budgetStatus(for category: Category) -> BudgetStatus? {
        guard let budget = category.budget, budget > 0 else { return nil }
        let spent = spendingForCategory(category)
        return BudgetStatus(spent: spent, budget: budget)
    }
    
    // MARK: - Persistence
    
    private func loadAllData() {
        loadAccounts()
        loadCategories()
        loadTransactions()
        loadGoals()
        loadRecurring()
        loadUserProfile()
        loadAppState()
    }
    
    private func loadAccounts() {
        if let data = defaults.data(forKey: Keys.accounts),
           let decoded = try? decoder.decode([Account].self, from: data) {
            accounts = decoded
        }
    }
    
    private func saveAccounts() {
        if let encoded = try? encoder.encode(accounts) {
            defaults.set(encoded, forKey: Keys.accounts)
        }
    }
    
    private func loadCategories() {
        if let data = defaults.data(forKey: Keys.categories),
           let decoded = try? decoder.decode([Category].self, from: data) {
            categories = decoded
        }
    }
    
    private func saveCategories() {
        if let encoded = try? encoder.encode(categories) {
            defaults.set(encoded, forKey: Keys.categories)
        }
    }
    
    private func loadTransactions() {
        if let data = defaults.data(forKey: Keys.transactions),
           let decoded = try? decoder.decode([Transaction].self, from: data) {
            transactions = decoded
        }
    }
    
    private func saveTransactions() {
        if let encoded = try? encoder.encode(transactions) {
            defaults.set(encoded, forKey: Keys.transactions)
        }
    }
    
    private func loadGoals() {
        if let data = defaults.data(forKey: Keys.goals),
           let decoded = try? decoder.decode([Goal].self, from: data) {
            goals = decoded
        }
    }
    
    private func saveGoals() {
        if let encoded = try? encoder.encode(goals) {
            defaults.set(encoded, forKey: Keys.goals)
        }
    }
    
    private func loadRecurring() {
        if let data = defaults.data(forKey: Keys.recurring),
           let decoded = try? decoder.decode([RecurringTransaction].self, from: data) {
            recurringTransactions = decoded
        }
    }
    
    private func saveRecurring() {
        if let encoded = try? encoder.encode(recurringTransactions) {
            defaults.set(encoded, forKey: Keys.recurring)
        }
    }
    
    private func loadUserProfile() {
        if let data = defaults.data(forKey: Keys.userProfile),
           let decoded = try? decoder.decode(UserProfile.self, from: data) {
            userProfile = decoded
        }
    }
    
    private func saveUserProfile() {
        if let encoded = try? encoder.encode(userProfile) {
            defaults.set(encoded, forKey: Keys.userProfile)
        }
    }
    
    private func loadAppState() {
        if let data = defaults.data(forKey: Keys.appState),
           let decoded = try? decoder.decode(AppState.self, from: data) {
            appState = decoded
        }
    }
    
    private func saveAppState() {
        if let encoded = try? encoder.encode(appState) {
            defaults.set(encoded, forKey: Keys.appState)
        }
    }
    
    // MARK: - Debug / Reset
    
    func resetAllData() {
        accounts = Account.defaultAccounts
        categories = [] // Empty - user creates their own!
        transactions = []
        goals = []
        recurringTransactions = []
        userProfile = UserProfile()
        appState = AppState()
        
        saveAccounts()
        saveCategories()
        saveTransactions()
        saveGoals()
        saveRecurring()
        saveUserProfile()
        saveAppState()
    }
}
