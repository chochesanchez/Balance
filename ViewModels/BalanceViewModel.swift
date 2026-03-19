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
    @Published var debts: [Debt] = []
    @Published var userProfile: UserProfile = UserProfile()
    @Published var appState: AppState = AppState()
    /// Set when a contribution crosses a 25/50/75/100% milestone. Views observe this to show a celebration banner.
    @Published var recentMilestone: (goalId: UUID, pct: Int)? = nil

    /// Cached weekly balance history — updated automatically after any transaction change.
    @Published private(set) var weeklyHistory: [(weekLabel: String, endDate: Date, balance: Double)] = []

    // MARK: - iCloud Sync State
    @Published private(set) var iCloudSyncEnabled: Bool = false
    @Published private(set) var lastSyncDate: Date? = nil

    // MARK: - Private Properties
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let sync = iCloudSyncManager.shared
    private var metadataQuery: NSMetadataQuery?

    // Storage Keys
    private enum Keys {
        static let accounts      = "balance_accounts"
        static let categories    = "balance_categories"
        static let transactions  = "balance_transactions"
        static let goals         = "balance_goals"
        static let recurring     = "balance_recurring"
        static let debts         = "balance_debts"
        static let userProfile   = "balance_userProfile"
        static let appState      = "balance_appState"
    }

    // iCloud file names
    private enum iCloudFiles {
        static let accounts      = "accounts.json"
        static let categories    = "categories.json"
        static let transactions  = "transactions.json"
        static let goals         = "goals.json"
        static let recurring     = "recurring.json"
        static let debts         = "debts.json"
        static let userProfile   = "userProfile.json"
        static let appState      = "appState.json"
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
        let accountsTotal = accounts.reduce(0) { $0 + balanceForAccount($1) }
        return accountsTotal + totalEnvelopeBalance
    }

    /// Net worth = all accounts + savings pots − active debts owed by the user
    var netWorth: Double {
        totalBalance - totalOutstandingOwed
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
        categories.filter { $0.type == .expense || $0.type == .both }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var incomeCategories: [Category] {
        categories.filter { $0.type == .income || $0.type == .both }.sorted { $0.sortOrder < $1.sortOrder }
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
        refreshWeeklyHistory()
        Haptics.success()
    }

    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            saveTransactions()
            Task { self.refreshWeeklyHistory() }
        }
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        saveTransactions()
        refreshWeeklyHistory()
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
        
        let transaction = Transaction(
            amount: recurring.amount,
            type: recurring.type,
            accountId: recurring.accountId,
            categoryId: recurring.categoryId,
            title: recurring.title,
            note: recurring.note,
            date: recurring.startDate,
            recurringId: recurring.id
        )
        addTransaction(transaction)
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            Task { @MainActor [weak self] in
                self?.appState.notificationsEnabled = granted
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
        // Null out goalId on linked transactions so orphaned transfers don't ghost account balances
        let hasLinkedTx = transactions.contains { $0.goalId == goal.id }
        if hasLinkedTx {
            transactions = transactions.map { tx in
                guard tx.goalId == goal.id else { return tx }
                var updated = tx
                updated.goalId = nil
                return updated
            }
            saveTransactions()
        }
        goals.removeAll { $0.id == goal.id }
        saveGoals()
    }

    // MARK: - Debt Functions

    func addDebt(_ debt: Debt) {
        debts.append(debt)
        saveDebts()
    }

    func updateDebt(_ debt: Debt) {
        if let index = debts.firstIndex(where: { $0.id == debt.id }) {
            debts[index] = debt
            saveDebts()
        }
    }

    func deleteDebt(_ debt: Debt) {
        debts.removeAll { $0.id == debt.id }
        saveDebts()
    }

    func recordDebtPayment(_ payment: DebtPayment, debtId: UUID, fromAccountId: UUID? = nil) {
        guard let index = debts.firstIndex(where: { $0.id == debtId }) else { return }
        let debt = debts[index]
        debts[index].payments.append(payment)
        debts[index].paidAmount += payment.amount
        if debts[index].paidAmount >= debts[index].totalAmount {
            debts[index].isSettled = true
        }
        saveDebts()

        // Create a transaction to reflect the actual account impact
        if let accountId = fromAccountId {
            let tx = Transaction(
                amount: payment.amount,
                type: debt.type == .iOwe ? .expense : .income,
                accountId: accountId,
                title: "\(debt.title) — \(debt.type == .iOwe ? "Payment" : "Receipt")",
                note: payment.note,
                date: payment.date
            )
            addTransaction(tx)
        }
    }

    // MARK: - Debt Analytics

    var activeDebts: [Debt] { debts.filter { !$0.isSettled } }
    var overdueDebts: [Debt] { debts.filter { $0.isOverdue } }

    var upcomingDebts: [Debt] {
        let cutoff = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return debts.filter { !$0.isSettled && ($0.dueDate.map { $0 <= cutoff } ?? false) }
    }

    var totalOutstandingOwed: Double {
        debts.filter { !$0.isSettled && $0.type == .iOwe }.reduce(0) { $0 + $1.remaining }
    }

    var totalOutstandingOwedToMe: Double {
        debts.filter { !$0.isSettled && $0.type == .owedToMe }.reduce(0) { $0 + $1.remaining }
    }

    var debtRecommendations: [DebtRecommendation] {
        var recs: [DebtRecommendation] = []
        let active = activeDebts

        // Overdue I-Owe debts (urgent)
        for d in overdueDebts.filter({ $0.type == .iOwe }).prefix(2) {
            let days = Calendar.current.dateComponents([.day], from: d.dueDate ?? Date(), to: Date()).day ?? 0
            recs.append(DebtRecommendation(
                icon: "exclamationmark.triangle.fill",
                message: "Pay \"\(d.title)\" — overdue by \(days) day\(days == 1 ? "" : "s")",
                severity: .warning, debtId: d.id))
        }

        // Overdue owed-to-me (follow up)
        for d in overdueDebts.filter({ $0.type == .owedToMe }).prefix(1) {
            let days = Calendar.current.dateComponents([.day], from: d.dueDate ?? Date(), to: Date()).day ?? 0
            recs.append(DebtRecommendation(
                icon: "person.fill.questionmark",
                message: "Follow up with \(d.person.isEmpty ? "them" : d.person) — overdue \(days)d",
                severity: .warning, debtId: d.id))
        }

        // Due within 7 days
        let soon = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        for d in active.filter({ !$0.isOverdue && ($0.dueDate.map { $0 <= soon } ?? false) && $0.type == .iOwe }).prefix(1) {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: d.dueDate ?? Date()).day ?? 0
            recs.append(DebtRecommendation(
                icon: "calendar.badge.exclamationmark",
                message: "\"\(d.title)\" due in \(days) day\(days == 1 ? "" : "s")",
                severity: .neutral, debtId: d.id))
        }

        // Highest interest rate
        if let highestInterest = active.filter({ $0.type == .iOwe && ($0.interestRate ?? 0) > 0 })
            .max(by: { ($0.interestRate ?? 0) < ($1.interestRate ?? 0) }) {
            let rate = Int((highestInterest.interestRate ?? 0).rounded())
            recs.append(DebtRecommendation(
                icon: "chart.line.uptrend.xyaxis",
                message: "Pay \"\(highestInterest.title)\" first — \(rate)% interest",
                severity: .neutral, debtId: highestInterest.id))
        }

        // All clear
        if active.isEmpty && !debts.isEmpty {
            recs.append(DebtRecommendation(
                icon: "checkmark.seal.fill",
                message: "All debts settled — great job!",
                severity: .positive, debtId: nil))
        }

        return recs
    }
    
    func contributeToGoal(_ goal: Goal, amount: Double, fromAccountId: UUID? = nil) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            var updated = goal
            let prevProgress = updated.targetAmount > 0 ? updated.currentAmount / updated.targetAmount : 0
            updated.currentAmount += amount
            if updated.currentAmount < 0 { updated.currentAmount = 0 }
            if updated.goalType == .goal && updated.targetAmount > 0 && updated.currentAmount >= updated.targetAmount {
                updated.isCompleted = true
            }
            goals[index] = updated
            saveGoals()

            // Streak: only for manual goals with a positive contribution
            if amount > 0 && updated.linkedAccountId == nil {
                updateGoalStreak(for: goal.id)
            }

            // Milestone detection: check if we just crossed 25/50/75/100%
            if amount > 0 && updated.targetAmount > 0 {
                let newProgress = updated.currentAmount / updated.targetAmount
                for pct in [1.0, 0.75, 0.5, 0.25] {
                    if prevProgress < pct && newProgress >= pct {
                        DispatchQueue.main.async {
                            self.recentMilestone = (goalId: goal.id, pct: Int(pct * 100))
                        }
                        break
                    }
                }
            }

            if let accountId = fromAccountId, abs(amount) > 0 {
                let isWithdraw = amount < 0
                let typeName = goal.goalType == .envelope ? "Savings Pot" : "Goal"
                let title = isWithdraw
                    ? "Withdraw from \(goal.title)"
                    : "Add to \(goal.title)"
                let transaction = Transaction(
                    amount: abs(amount),
                    type: .transfer,
                    // Contribution: debit fromAccount (accountId = source, toAccountId = nil → pot)
                    // Withdrawal:   credit fromAccount (accountId = goal.id acts as virtual pot UUID
                    //               matching no real account, toAccountId = destination account)
                    accountId: isWithdraw ? goal.id : accountId,
                    toAccountId: isWithdraw ? accountId : nil,
                    title: title,
                    note: "\(typeName) transfer",
                    goalId: goal.id
                )
                addTransaction(transaction)
            }
        }
    }

    func updateGoalStreak(for goalId: UUID) {
        guard let idx = goals.firstIndex(where: { $0.id == goalId }) else { return }
        var goal = goals[idx]
        let cal = Calendar.current
        let now = Date()

        if let last = goal.lastStreakDate {
            let sameWeek = cal.isDate(last, equalTo: now, toGranularity: .weekOfYear)
            let prevWeek: Bool = {
                guard let prevWeekDate = cal.date(byAdding: .weekOfYear, value: -1, to: now) else { return false }
                return cal.isDate(last, equalTo: prevWeekDate, toGranularity: .weekOfYear)
            }()
            if sameWeek { return }
            else if prevWeek { goal.streak += 1 }
            else { goal.streak = 1 }
        } else {
            goal.streak = 1
        }

        goal.longestStreak = max(goal.longestStreak, goal.streak)
        goal.lastStreakDate = now
        goals[idx] = goal
        saveGoals()
    }

    /// Suggested emergency fund target = 3× average monthly expenses (last 3 months).
    var emergencyFundSuggestedTarget: Double {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let expenses = transactions.filter { $0.type == .expense && $0.date >= threeMonthsAgo }
        let total = expenses.reduce(0) { $0 + $1.amount }
        let monthly = total / 3
        return monthly * 3   // 3-month cushion
    }
    
    // MARK: - Envelope / Savings Pot Helpers
    
    var envelopes: [Goal] {
        goals.filter { $0.goalType == .envelope && !$0.isCompleted }
    }
    
    var activeGoals: [Goal] {
        goals.filter { $0.goalType == .goal && !$0.isCompleted }
    }
    
    var totalEnvelopeBalance: Double {
        envelopes.reduce(0) { $0 + $1.currentAmount }
    }
    
    // MARK: - Weekly Balance History

    /// Recomputes the cached `weeklyHistory`. Call after any transaction or account mutation.
    func refreshWeeklyHistory() {
        weeklyHistory = weeklyBalanceHistory()
    }

    func weeklyBalanceHistory(weeks: Int = 8) -> [(weekLabel: String, endDate: Date, balance: Double)] {
        let cal = Calendar.current
        var result: [(weekLabel: String, endDate: Date, balance: Double)] = []

        let totalInitialBalance = accounts.reduce(0.0) { $0 + $1.initialBalance }
        let df = DateFormatter()  // created once outside the loop
        df.dateFormat = "MMM d"

        for i in (0..<weeks).reversed() {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -i, to: Date()),
                  let weekInterval = cal.dateInterval(of: .weekOfYear, for: weekStart) else { continue }

            let weekEnd = weekInterval.end

            let transactionsUpToWeekEnd = transactions.filter { $0.date < weekEnd }
            let netTransactions = transactionsUpToWeekEnd.reduce(0.0) { total, tx in
                switch tx.type {
                case .income: return total + tx.amount
                case .expense: return total - tx.amount
                case .transfer: return total
                }
            }

            let balance = totalInitialBalance + netTransactions
            let label = i == 0 ? "Now" : df.string(from: weekInterval.start)

            result.append((weekLabel: label, endDate: weekEnd, balance: balance))
        }

        return result
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
    
    func saveData() {
        saveAppState()
    }
    
    // MARK: - Daily Spending Data (for Charts)
    
    func dailySpending(for range: TimeRange, referenceDate: Date = Date()) -> [(date: Date, income: Double, expense: Double)] {
        guard let interval = range.dateInterval(for: referenceDate) else { return [] }
        let cal = Calendar.current
        let rangeTransactions = transactions.filter { $0.date >= interval.start && $0.date < interval.end }
        
        var dailyData: [Date: (income: Double, expense: Double)] = [:]
        var current = interval.start
        while current < interval.end {
            let dayStart = cal.startOfDay(for: current)
            dailyData[dayStart] = (0, 0)
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        
        for tx in rangeTransactions {
            let dayStart = cal.startOfDay(for: tx.date)
            let existing = dailyData[dayStart] ?? (0, 0)
            if tx.type == .income {
                dailyData[dayStart] = (existing.income + tx.amount, existing.expense)
            } else if tx.type == .expense {
                dailyData[dayStart] = (existing.income, existing.expense + tx.amount)
            }
        }
        
        return dailyData.sorted { $0.key < $1.key }.map { ($0.key, $0.value.income, $0.value.expense) }
    }
    
    func incomeByCategory(for month: Date = Date()) -> [(category: Category, amount: Double, percentage: Double)] {
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? month
        let endOfMonth = cal.date(byAdding: .month, value: 1, to: startOfMonth) ?? month
        
        let monthIncome = transactions.filter {
            $0.type == .income && $0.date >= startOfMonth && $0.date < endOfMonth
        }
        
        let totalIncome = monthIncome.reduce(0) { $0 + $1.amount }
        guard totalIncome > 0 else { return [] }
        
        let grouped = Dictionary(grouping: monthIncome) { $0.categoryId }
        
        return grouped.compactMap { catId, txs in
            guard let category = categories.first(where: { $0.id == catId }) else { return nil }
            let amount = txs.reduce(0) { $0 + $1.amount }
            return (category: category, amount: amount, percentage: (amount / totalIncome) * 100)
        }.sorted { $0.amount > $1.amount }
    }
    
    var largestExpense: Transaction? {
        currentRangeTransactions.filter { $0.type == .expense }.max(by: { $0.amount < $1.amount })
    }
    
    var averageTransactionAmount: Double {
        let expenses = currentRangeTransactions.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return 0 }
        return expenses.reduce(0) { $0 + $1.amount } / Double(expenses.count)
    }
    
    var mostActiveDay: String? {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: currentRangeTransactions) { cal.component(.weekday, from: $0.date) }
        guard let mostActive = grouped.max(by: { $0.value.count < $1.value.count }) else { return nil }
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[mostActive.key - 1]
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
        
        // 7. Spending anomaly — category spending 2× or more vs previous period
        for stat in topCategoryStats.prefix(5) {
            if let delta = stat.deltaFromPrevious, delta > 1.0 {
                let mult = Int((delta + 1).rounded())
                insights.append(Insight(
                    type: .category,
                    title: "Unusual spend: \(stat.category.name)",
                    message: "You've spent \(mult)× more on \(stat.category.name) than last \(timeLabel).",
                    severity: .warning,
                    relatedCategoryId: stat.category.id
                ))
                break
            }
        }

        // 8. Overdue debts
        let overdueCount = overdueDebts.count
        if overdueCount > 0 {
            insights.append(Insight(
                type: .habit,
                title: "\(overdueCount) overdue debt\(overdueCount == 1 ? "" : "s")",
                message: overdueCount == 1 ? "You have a payment past its due date." : "You have \(overdueCount) payments past their due dates.",
                severity: .warning,
                icon: "creditcard.fill"
            ))
        }

        // 9. Goal: no contributions in 30+ days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let activeManualGoals = goals.filter { $0.goalType == .goal && !$0.isCompleted && $0.linkedAccountId == nil && $0.targetAmount > 0 }
        for goal in activeManualGoals.prefix(3) {
            let recent = transactions.filter { $0.goalId == goal.id && $0.date > thirtyDaysAgo && $0.toAccountId == nil }
            if recent.isEmpty && goal.currentAmount < goal.targetAmount {
                insights.append(Insight(
                    type: .goal,
                    title: "Goal reminder",
                    message: "No contributions to \"\(goal.title)\" in 30 days.",
                    severity: .warning,
                    icon: "exclamationmark.circle.fill"
                ))
                break
            }
        }

        // 10. Goal on track / behind
        for goal in goals.filter({ $0.goalType == .goal && !$0.isCompleted && $0.deadline != nil }).prefix(2) {
            switch status(for: goal) {
            case .onTrack:
                if let eta = goalETA(for: goal) {
                    let formatter = DateFormatter(); formatter.dateStyle = .medium
                    insights.append(Insight(
                        type: .goal,
                        title: "On track: \(goal.title)",
                        message: "You're on pace to reach your goal by \(formatter.string(from: eta)).",
                        severity: .positive,
                        icon: "checkmark.seal.fill"
                    ))
                }
            case .behind:
                insights.append(Insight(
                    type: .goal,
                    title: "Behind: \(goal.title)",
                    message: "\"\(goal.title)\" is falling behind schedule. Try contributing more.",
                    severity: .warning,
                    icon: "clock.badge.exclamationmark.fill"
                ))
            default: break
            }
            break  // max one goal status insight
        }

        // Limit to 5 insights for UI
        return Array(insights.prefix(5))
    }
    
    // MARK: - Debt Recommendation Type

    struct DebtRecommendation: Identifiable {
        let id = UUID()
        let icon: String
        let message: String
        let severity: InsightSeverity
        let debtId: UUID?
    }

    /// Format currency compactly for insights
    private func formatCurrencyCompact(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = appState.selectedCurrency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
    
    // MARK: - Predictive Analytics

    /// Project end-of-month spending based on the daily average so far this month.
    var monthEndForecast: (projected: Double, dailyAvg: Double, daysRemaining: Int, daysPassed: Int, totalDays: Int)? {
        let cal = Calendar.current
        guard let interval = TimeRange.monthly.dateInterval() else { return nil }
        let daysPassed = max(cal.dateComponents([.day], from: interval.start, to: Date()).day ?? 1, 1)
        let totalDays  = cal.dateComponents([.day], from: interval.start, to: interval.end).day ?? 30
        let remaining  = max(totalDays - daysPassed, 0)
        let spent = transactions.filter {
            $0.type == .expense && $0.date >= interval.start && $0.date < interval.end
        }.reduce(0) { $0 + $1.amount }
        let dailyAvg = spent / Double(daysPassed)
        return (projected: spent + dailyAvg * Double(remaining),
                dailyAvg: dailyAvg,
                daysRemaining: remaining,
                daysPassed: daysPassed,
                totalDays: totalDays)
    }

    /// Returns the effective current amount for a goal.
    /// For account-linked goals, reflects the live account balance.
    func effectiveCurrentAmount(for goal: Goal) -> Double {
        if let accountId = goal.linkedAccountId,
           let account = accounts.first(where: { $0.id == accountId }) {
            return balanceForAccount(account)
        }
        return goal.currentAmount
    }

    /// Estimate when a goal will be reached based on the last 3 months of contributions.
    func goalETA(for goal: Goal) -> Date? {
        let current = effectiveCurrentAmount(for: goal)
        guard !goal.isCompleted, goal.targetAmount > current, current > 0 else { return nil }
        let cal = Calendar.current
        let threeMonthsAgo = cal.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let months = max(cal.dateComponents([.month], from: threeMonthsAgo, to: Date()).month ?? 1, 1)
        let monthlyAvg: Double
        if goal.linkedAccountId != nil {
            // For account-linked goals, estimate monthly growth from balance history
            let oldBalance = weeklyBalanceHistory(weeks: 13).first.map { $0.balance } ?? current
            monthlyAvg = max((current - oldBalance) / 3.0, 0)
        } else {
            let contributions = transactions.filter { $0.goalId == goal.id && $0.date >= threeMonthsAgo && $0.toAccountId == nil }
            guard !contributions.isEmpty else { return nil }
            monthlyAvg = contributions.reduce(0) { $0 + $1.amount } / Double(months)
        }
        guard monthlyAvg > 0 else { return nil }
        let monthsLeft = (goal.targetAmount - current) / monthlyAvg
        return cal.date(byAdding: .month, value: Int(ceil(monthsLeft)), to: Date())
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
        iCloudSyncEnabled = sync.isAvailable
        if sync.isAvailable {
            loadWithiCloudMerge()
        } else {
            loadFromUserDefaults()
        }
        setupExternalObservers()
        startMetadataQuery()
        refreshWeeklyHistory()
    }

    // MARK: Load helpers

    private func loadFromUserDefaults() {
        loadAccounts(); loadCategories(); loadTransactions()
        loadGoals(); loadRecurring(); loadDebts(); loadUserProfile(); loadAppState()
    }

    private func loadWithiCloudMerge() {
        loadMerged([Account].self,              localKey: Keys.accounts,     iCloudFile: iCloudFiles.accounts)     { self.accounts = $0 }
        loadMerged([Category].self,             localKey: Keys.categories,   iCloudFile: iCloudFiles.categories)   { self.categories = $0 }
        loadMerged([Transaction].self,          localKey: Keys.transactions, iCloudFile: iCloudFiles.transactions) { self.transactions = $0 }
        loadMerged([Goal].self,                 localKey: Keys.goals,        iCloudFile: iCloudFiles.goals)        { self.goals = $0 }
        loadMerged([RecurringTransaction].self, localKey: Keys.recurring,    iCloudFile: iCloudFiles.recurring)    { self.recurringTransactions = $0 }
        loadMerged([Debt].self,                 localKey: Keys.debts,        iCloudFile: iCloudFiles.debts)        { self.debts = $0 }
        loadMerged(UserProfile.self,            localKey: Keys.userProfile,  iCloudFile: iCloudFiles.userProfile)  { self.userProfile = $0 }
        loadMerged(AppState.self,               localKey: Keys.appState,     iCloudFile: iCloudFiles.appState)     { self.appState = $0 }
    }

    /// Loads a Codable type, preferring iCloud data if it is newer than the local copy.
    private func loadMerged<T: Codable>(_ type: T.Type, localKey: String, iCloudFile: String, assign: (T) -> Void) {
        let localData  = defaults.data(forKey: localKey)
        let cloudData  = sync.read(filename: iCloudFile)
        let cloudDate  = sync.modificationDate(filename: iCloudFile) ?? .distantPast
        let localDate  = (defaults.object(forKey: localKey + "_date") as? Date) ?? .distantPast
        let useCloud   = cloudData != nil && cloudDate > localDate
        let data       = useCloud ? cloudData : localData
        if let data, let decoded = try? decoder.decode(type, from: data) {
            assign(decoded)
            if useCloud { defaults.set(data, forKey: localKey) }
        }
    }

    // MARK: iCloud observers

    private func setupExternalObservers() {
        // Reload when app returns to foreground (picks up changes from other devices)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.sync.isAvailable else { return }
                self.loadWithiCloudMerge()
                self.refreshWeeklyHistory()
            }
        }
        // Reload when Back Tap intent writes a transaction while the app is backgrounded
        NotificationCenter.default.addObserver(
            forName: Notification.Name("BalanceExternalDataChanged"),
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.loadTransactions()
                self?.refreshWeeklyHistory()
            }
        }
    }

    private func startMetadataQuery() {
        guard sync.isAvailable else { return }
        let q = NSMetadataQuery()
        q.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        q.predicate = NSPredicate(format: "%K LIKE '*.json'", NSMetadataItemFSNameKey)
        q.notificationBatchingInterval = 1.0
        NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidUpdate,
            object: q, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.loadWithiCloudMerge()
                self?.refreshWeeklyHistory()
                self?.lastSyncDate = Date()
            }
        }
        q.start()
        metadataQuery = q
    }

    // MARK: Individual load methods

    private func loadAccounts() {
        if let data = defaults.data(forKey: Keys.accounts),
           let decoded = try? decoder.decode([Account].self, from: data) {
            accounts = decoded
        }
    }

    private func saveAccounts() {
        if let encoded = try? encoder.encode(accounts) {
            defaults.set(encoded, forKey: Keys.accounts)
            defaults.set(Date(), forKey: Keys.accounts + "_date")
            if sync.isAvailable { sync.write(encoded, filename: iCloudFiles.accounts); lastSyncDate = Date() }
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
            defaults.set(Date(), forKey: Keys.categories + "_date")
            if sync.isAvailable { sync.write(encoded, filename: iCloudFiles.categories); lastSyncDate = Date() }
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
            defaults.set(Date(), forKey: Keys.transactions + "_date")
            if sync.isAvailable { sync.write(encoded, filename: iCloudFiles.transactions); lastSyncDate = Date() }
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
            defaults.set(Date(), forKey: Keys.goals + "_date")
            if sync.isAvailable { sync.write(encoded, filename: iCloudFiles.goals); lastSyncDate = Date() }
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
            defaults.set(Date(), forKey: Keys.recurring + "_date")
            if sync.isAvailable { sync.write(encoded, filename: iCloudFiles.recurring); lastSyncDate = Date() }
        }
    }

    private func loadDebts() {
        if let data = defaults.data(forKey: Keys.debts),
           let decoded = try? decoder.decode([Debt].self, from: data) {
            debts = decoded
        }
    }

    private func saveDebts() {
        if let encoded = try? encoder.encode(debts) {
            defaults.set(encoded, forKey: Keys.debts)
            defaults.set(Date(), forKey: Keys.debts + "_date")
            if sync.isAvailable { sync.write(encoded, filename: iCloudFiles.debts); lastSyncDate = Date() }
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
            defaults.set(Date(), forKey: Keys.userProfile + "_date")
            if sync.isAvailable { sync.write(encoded, filename: iCloudFiles.userProfile); lastSyncDate = Date() }
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
            defaults.set(Date(), forKey: Keys.appState + "_date")
            if sync.isAvailable { sync.write(encoded, filename: iCloudFiles.appState); lastSyncDate = Date() }
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
        refreshWeeklyHistory()
    }
}
