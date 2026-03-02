import AppIntents
import SwiftUI

// MARK: - Record Expense Intent
struct RecordExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Record Expense"
    static let description = IntentDescription("Open Balance to record an expense")
    static let openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationState.shared.pendingTab = 2
        NavigationState.shared.pendingType = .expense
        return .result()
    }
}

// MARK: - Record Income Intent
struct RecordIncomeIntent: AppIntent {
    static let title: LocalizedStringResource = "Record Income"
    static let description = IntentDescription("Open Balance to record income")
    static let openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationState.shared.pendingTab = 2
        NavigationState.shared.pendingType = .income
        return .result()
    }
}

// MARK: - Show Balance Intent
struct ShowBalanceIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Balance"
    static let description = IntentDescription("Open Balance to see your total balance")
    static let openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationState.shared.pendingTab = 0
        return .result()
    }
}

// MARK: - App Shortcuts Provider
struct BalanceShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordExpenseIntent(),
            phrases: [
                "Record expense in \(.applicationName)",
                "Add expense in \(.applicationName)",
                "Log spending in \(.applicationName)"
            ],
            shortTitle: "Record Expense",
            systemImageName: "arrow.up.circle.fill"
        )
        
        AppShortcut(
            intent: RecordIncomeIntent(),
            phrases: [
                "Record income in \(.applicationName)",
                "Add income in \(.applicationName)",
                "Log earnings in \(.applicationName)"
            ],
            shortTitle: "Record Income",
            systemImageName: "arrow.down.circle.fill"
        )
        
        AppShortcut(
            intent: ShowBalanceIntent(),
            phrases: [
                "Show my balance in \(.applicationName)",
                "Check balance in \(.applicationName)",
                "How much money do I have in \(.applicationName)"
            ],
            shortTitle: "Show Balance",
            systemImageName: "dollarsign.circle.fill"
        )
    }
}

// MARK: - Navigation State (shared singleton for deep linking from intents)
@MainActor
class NavigationState: ObservableObject {
    static let shared = NavigationState()
    @Published var pendingTab: Int?
    @Published var pendingType: TransactionType?
}
