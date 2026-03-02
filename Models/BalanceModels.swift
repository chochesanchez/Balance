import Foundation
import SwiftUI

// MARK: - Balance Models
// Restructured data models with clear separation of concerns

// MARK: - Account Model
/// Represents a financial account (Cash, Checking, Credit Card, etc.)
struct Account: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var type: AccountType
    var icon: String
    var color: String // Hex color
    var initialBalance: Double
    var isDefault: Bool
    var note: String? // Optional note/subtitle
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        icon: String = "dollarsign.circle.fill",
        color: String = "#007AFF",
        initialBalance: Double = 0,
        isDefault: Bool = false,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon
        self.color = color
        self.initialBalance = initialBalance
        self.isDefault = isDefault
        self.note = note
        self.createdAt = createdAt
    }
    
    var colorValue: Color {
        Color(hex: color)
    }
}

enum AccountType: String, CaseIterable, Codable {
    case cash = "Cash"
    case checking = "Bank Account"
    case debitCard = "Debit Card"
    case savings = "Savings"
    case creditCard = "Credit Card"
    case investment = "Investment"
    case digitalWallet = "Digital Wallet"
    case other = "Other"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if raw == "Checking" { self = .checking; return }
        guard let value = AccountType(rawValue: raw) else {
            self = .other; return
        }
        self = value
    }
    
    var defaultIcon: String {
        switch self {
        case .cash: return "dollarsign.circle.fill"
        case .checking: return "building.columns.fill"
        case .debitCard: return "creditcard.fill"
        case .savings: return "banknote.fill"
        case .creditCard: return "creditcard.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .digitalWallet: return "iphone.gen3"
        case .other: return "wallet.pass.fill"
        }
    }
    
    var defaultColor: String {
        switch self {
        case .cash: return "#34C759"
        case .checking: return "#007AFF"
        case .debitCard: return "#0191FF"
        case .savings: return "#5856D6"
        case .creditCard: return "#FF9500"
        case .investment: return "#AF52DE"
        case .digitalWallet: return "#00C7BE"
        case .other: return "#8E8E93"
        }
    }
}

// MARK: - Category Model
/// Represents a spending/income category (Food, Transport, Salary, etc.)
struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var color: String // Hex color
    var type: CategoryType
    var isSystem: Bool // System categories can't be deleted
    var budget: Double? // Optional monthly budget
    var sortOrder: Int
    var note: String? // Optional note/description
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: String,
        type: CategoryType,
        isSystem: Bool = false,
        budget: Double? = nil,
        sortOrder: Int = 0,
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.type = type
        self.isSystem = isSystem
        self.budget = budget
        self.sortOrder = sortOrder
        self.note = note
    }
    
    var colorValue: Color {
        Color(hex: color)
    }
}

enum CategoryType: String, Codable, CaseIterable {
    case expense = "Expense"
    case income = "Income"
    case both = "Both"
}

// MARK: - Transaction Model
/// Represents a financial transaction
struct Transaction: Identifiable, Codable {
    let id: UUID
    var amount: Double // Always positive, type determines direction
    var type: TransactionType
    var accountId: UUID
    var categoryId: UUID?
    var toAccountId: UUID? // For transfers
    var title: String
    var note: String
    var date: Date
    var createdAt: Date
    var recurringId: UUID? // Link to recurring transaction
    
    init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        accountId: UUID,
        categoryId: UUID? = nil,
        toAccountId: UUID? = nil,
        title: String = "",
        note: String = "",
        date: Date = Date(),
        createdAt: Date = Date(),
        recurringId: UUID? = nil
    ) {
        self.id = id
        self.amount = abs(amount) // Ensure positive
        self.type = type
        self.accountId = accountId
        self.categoryId = categoryId
        self.toAccountId = toAccountId
        self.title = title
        self.note = note
        self.date = date
        self.createdAt = createdAt
        self.recurringId = recurringId
    }
    
    var signedAmount: Double {
        switch type {
        case .income: return amount
        case .expense: return -amount
        case .transfer: return 0 // Transfers don't affect total
        }
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
    case transfer = "Transfer"
    
    var color: Color {
        switch self {
        case .income: return Theme.Colors.income
        case .expense: return Theme.Colors.expense
        case .transfer: return Theme.Colors.transfer
        }
    }
    
    var icon: String {
        switch self {
        case .income: return Theme.Icons.income
        case .expense: return Theme.Icons.expense
        case .transfer: return Theme.Icons.transfer
        }
    }
}

// MARK: - Recurring Transaction Model
/// Represents a recurring expense or income
struct RecurringTransaction: Identifiable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var type: TransactionType
    var accountId: UUID
    var categoryId: UUID?
    var frequency: RecurringFrequency
    var startDate: Date
    var endDate: Date? // Optional end date
    var nextDueDate: Date
    var lastProcessedDate: Date?
    var note: String
    var isActive: Bool
    var notifyDaysBefore: Int // Days before due date to notify
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        type: TransactionType,
        accountId: UUID,
        categoryId: UUID? = nil,
        frequency: RecurringFrequency,
        startDate: Date = Date(),
        endDate: Date? = nil,
        nextDueDate: Date? = nil,
        lastProcessedDate: Date? = nil,
        note: String = "",
        isActive: Bool = true,
        notifyDaysBefore: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = abs(amount)
        self.type = type
        self.accountId = accountId
        self.categoryId = categoryId
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.nextDueDate = nextDueDate ?? frequency.nextDate(from: startDate)
        self.lastProcessedDate = lastProcessedDate
        self.note = note
        self.isActive = isActive
        self.notifyDaysBefore = notifyDaysBefore
        self.createdAt = createdAt
    }
    
    var isDueToday: Bool {
        Calendar.current.isDateInToday(nextDueDate)
    }
    
    var isOverdue: Bool {
        nextDueDate < Date() && !isDueToday
    }
    
    var daysUntilDue: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextDueDate)
        return components.day ?? 0
    }
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    
    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar.badge.clock"
        case .biweekly: return "calendar"
        case .monthly: return "calendar.circle.fill"
        case .quarterly: return "chart.bar.fill"
        case .yearly: return "star.fill"
        }
    }
    
    func nextDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}

// MARK: - Goal Type
enum GoalType: String, Codable, CaseIterable {
    case goal = "Goal"
    case envelope = "Savings Pot"
}

// MARK: - Goal Model
struct Goal: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var icon: String
    var color: String
    var imageData: Data?
    var isCompleted: Bool
    var goalType: GoalType
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        targetAmount: Double = 0,
        currentAmount: Double = 0,
        deadline: Date? = nil,
        icon: String = "star.fill",
        color: String = "#007AFF",
        imageData: Data? = nil,
        isCompleted: Bool = false,
        goalType: GoalType = .goal,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.icon = icon
        self.color = color
        self.imageData = imageData
        self.isCompleted = isCompleted
        self.goalType = goalType
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        targetAmount = try container.decode(Double.self, forKey: .targetAmount)
        currentAmount = try container.decode(Double.self, forKey: .currentAmount)
        deadline = try container.decodeIfPresent(Date.self, forKey: .deadline)
        icon = try container.decode(String.self, forKey: .icon)
        color = try container.decode(String.self, forKey: .color)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        goalType = try container.decodeIfPresent(GoalType.self, forKey: .goalType) ?? .goal
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min((currentAmount / targetAmount) * 100, 100)
    }
    
    var remaining: Double {
        max(targetAmount - currentAmount, 0)
    }
    
    var colorValue: Color {
        Color(hex: color)
    }
    
    var isEnvelope: Bool { goalType == .envelope }
}

// MARK: - User Profile
struct UserProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var username: String
    var email: String
    var phone: String
    var profileImageData: Data?
    var monthlyIncomeRange: IncomeRange?
    var primaryGoal: FinancialGoal?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String = "",
        username: String = "",
        email: String = "",
        phone: String = "",
        profileImageData: Data? = nil,
        monthlyIncomeRange: IncomeRange? = nil,
        primaryGoal: FinancialGoal? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.email = email
        self.phone = phone
        self.profileImageData = profileImageData
        self.monthlyIncomeRange = monthlyIncomeRange
        self.primaryGoal = primaryGoal
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        profileImageData = try container.decodeIfPresent(Data.self, forKey: .profileImageData)
        monthlyIncomeRange = try container.decodeIfPresent(IncomeRange.self, forKey: .monthlyIncomeRange)
        primaryGoal = try container.decodeIfPresent(FinancialGoal.self, forKey: .primaryGoal)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

enum IncomeRange: String, Codable, CaseIterable {
    case under1k = "Less than $1,000"
    case from1kTo3k = "$1,000 - $3,000"
    case from3kTo5k = "$3,000 - $5,000"
    case from5kTo10k = "$5,000 - $10,000"
    case over10k = "More than $10,000"
    case preferNotToSay = "Prefer not to say"
}

enum FinancialGoal: String, Codable, CaseIterable {
    case saveMore = "Save more money"
    case trackSpending = "Track my spending"
    case reachGoal = "Reach a savings goal"
    case buildHabits = "Build better habits"
    
    var icon: String {
        switch self {
        case .saveMore: return "dollarsign.circle.fill"
        case .trackSpending: return "chart.bar.fill"
        case .reachGoal: return "target"
        case .buildHabits: return "arrow.up.right.circle.fill"
        }
    }
}

// MARK: - App State
struct AppState: Codable {
    var hasCompletedOnboarding: Bool
    var selectedCurrency: String
    var notificationsEnabled: Bool
    var preferredTimeRange: TimeRange
    var weeklySpendingLimit: Double
    var recurringReminders: Bool
    var goalReminders: Bool
    var weeklySummary: Bool
    var defaultTab: Int
    
    init(
        hasCompletedOnboarding: Bool = false,
        selectedCurrency: String = "USD",
        notificationsEnabled: Bool = true,
        preferredTimeRange: TimeRange = .monthly,
        weeklySpendingLimit: Double = 0,
        recurringReminders: Bool = true,
        goalReminders: Bool = true,
        weeklySummary: Bool = false,
        defaultTab: Int = 0
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedCurrency = selectedCurrency
        self.notificationsEnabled = notificationsEnabled
        self.preferredTimeRange = preferredTimeRange
        self.weeklySpendingLimit = weeklySpendingLimit
        self.recurringReminders = recurringReminders
        self.goalReminders = goalReminders
        self.weeklySummary = weeklySummary
        self.defaultTab = defaultTab
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        selectedCurrency = try container.decode(String.self, forKey: .selectedCurrency)
        notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        preferredTimeRange = try container.decode(TimeRange.self, forKey: .preferredTimeRange)
        weeklySpendingLimit = try container.decodeIfPresent(Double.self, forKey: .weeklySpendingLimit) ?? 0
        recurringReminders = try container.decodeIfPresent(Bool.self, forKey: .recurringReminders) ?? true
        goalReminders = try container.decodeIfPresent(Bool.self, forKey: .goalReminders) ?? true
        weeklySummary = try container.decodeIfPresent(Bool.self, forKey: .weeklySummary) ?? false
        defaultTab = try container.decodeIfPresent(Int.self, forKey: .defaultTab) ?? 0
    }
}

// MARK: - Time Range
/// Time scope for analytics and filtering
enum TimeRange: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
    var shortTitle: String {
        switch self {
        case .daily: return "Day"
        case .weekly: return "Week"
        case .monthly: return "Month"
        case .yearly: return "Year"
        }
    }
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }
    
    /// Returns the date range for this time scope
    func dateInterval(for referenceDate: Date = Date()) -> DateInterval? {
        let calendar = Calendar.current
        switch self {
        case .daily:
            let start = calendar.startOfDay(for: referenceDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? referenceDate
            return DateInterval(start: start, end: end)
        case .weekly:
            return calendar.dateInterval(of: .weekOfYear, for: referenceDate)
        case .monthly:
            return calendar.dateInterval(of: .month, for: referenceDate)
        case .yearly:
            return calendar.dateInterval(of: .year, for: referenceDate)
        }
    }
    
    /// Returns the previous period's date interval
    func previousDateInterval(for referenceDate: Date = Date()) -> DateInterval? {
        let calendar = Calendar.current
        guard let currentInterval = dateInterval(for: referenceDate),
              let previousStart = calendar.date(byAdding: calendarComponent, value: -1, to: currentInterval.start),
              let previousInterval = dateInterval(for: previousStart)
        else { return nil }
        return previousInterval
    }
    
    /// Check if a date falls within this time range
    func contains(_ date: Date, referenceDate: Date = Date()) -> Bool {
        guard let interval = dateInterval(for: referenceDate) else { return false }
        return date >= interval.start && date < interval.end
    }
}

// MARK: - Insight Model
/// Represents a smart insight about user's finances
enum InsightSeverity: String, Codable {
    case positive
    case neutral
    case warning
    
    var color: Color {
        switch self {
        case .positive: return Theme.Colors.income
        case .neutral: return Theme.Colors.primary
        case .warning: return Color.orange
        }
    }
    
    var icon: String {
        switch self {
        case .positive: return "checkmark.circle.fill"
        case .neutral: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

enum InsightType: String, Codable {
    case savings
    case spending
    case category
    case budget
    case goal
    case habit
    case tip
}

struct Insight: Identifiable {
    let id: UUID
    let type: InsightType
    let title: String
    let message: String
    let severity: InsightSeverity
    let icon: String?
    let actionLabel: String?
    let relatedCategoryId: UUID?
    
    init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        message: String,
        severity: InsightSeverity,
        icon: String? = nil,
        actionLabel: String? = nil,
        relatedCategoryId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.severity = severity
        self.icon = icon ?? severity.icon
        self.actionLabel = actionLabel
        self.relatedCategoryId = relatedCategoryId
    }
}

// MARK: - Category Statistics
/// Statistics for a category within a time range
struct CategoryStat: Identifiable {
    let id: UUID
    let category: Category
    let total: Double
    let transactionCount: Int
    let percentOfTotal: Double
    let deltaFromPrevious: Double? // Change vs previous period
    let averageTransaction: Double
    
    init(
        category: Category,
        total: Double,
        transactionCount: Int,
        percentOfTotal: Double = 0,
        deltaFromPrevious: Double? = nil,
        averageTransaction: Double = 0
    ) {
        self.id = category.id
        self.category = category
        self.total = total
        self.transactionCount = transactionCount
        self.percentOfTotal = percentOfTotal
        self.deltaFromPrevious = deltaFromPrevious
        self.averageTransaction = averageTransaction
    }
    
    var isAboveAverage: Bool {
        guard let delta = deltaFromPrevious else { return false }
        return delta > 0.15 // More than 15% above
    }
    
    var isBelowAverage: Bool {
        guard let delta = deltaFromPrevious else { return false }
        return delta < -0.15 // More than 15% below
    }
}

// MARK: - Budget Status
/// Visual status for budgets
enum BudgetStatus: String {
    case safe
    case atRisk
    case overspent
    
    var label: String {
        switch self {
        case .safe: return "Within Budget"
        case .atRisk: return "At Risk"
        case .overspent: return "Overspent"
        }
    }
    
    var color: Color {
        switch self {
        case .safe: return Theme.Colors.income
        case .atRisk: return Color.orange
        case .overspent: return Theme.Colors.expense
        }
    }
    
    var icon: String {
        switch self {
        case .safe: return "checkmark.circle.fill"
        case .atRisk: return "exclamationmark.triangle.fill"
        case .overspent: return "xmark.circle.fill"
        }
    }
    
    init(spent: Double, budget: Double) {
        guard budget > 0 else { self = .safe; return }
        let percent = spent / budget
        if percent > 1.0 {
            self = .overspent
        } else if percent >= 0.7 {
            self = .atRisk
        } else {
            self = .safe
        }
    }
}

// MARK: - Goal Status
/// Visual status for goals
enum GoalStatus: String {
    case onTrack
    case behind
    case completed
    case noDeadline
    
    var label: String {
        switch self {
        case .onTrack: return "On Track"
        case .behind: return "Behind"
        case .completed: return "Completed"
        case .noDeadline: return "In Progress"
        }
    }
    
    var color: Color {
        switch self {
        case .onTrack: return Theme.Colors.income
        case .behind: return Color.orange
        case .completed: return Theme.Colors.primary
        case .noDeadline: return Theme.Colors.secondaryText
        }
    }
    
    var icon: String {
        switch self {
        case .onTrack: return "arrow.up.right.circle.fill"
        case .behind: return "exclamationmark.triangle.fill"
        case .completed: return "checkmark.circle.fill"
        case .noDeadline: return "circle.dashed"
        }
    }
}

// MARK: - Default Data (EMPTY - User creates their own!)
extension Category {
    // No default categories - user creates their own!
    static var defaultExpenseCategories: [Category] { [] }
    static var defaultIncomeCategories: [Category] { [] }
}

extension Account {
    static var defaultAccounts: [Account] {
        [
            Account(name: "Cash", type: .cash, icon: "dollarsign.circle.fill", color: "#34C759", isDefault: true),
        ]
    }
}
