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

// MARK: - Account Entity (for account picker in Quick Add)
struct AccountEntity: AppEntity {
    var id: UUID
    var name: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Account"
    static let defaultQuery = AccountEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct AccountEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [AccountEntity] {
        Self.loadAll().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [AccountEntity] {
        Self.loadAll()
    }

    static func loadAll() -> [AccountEntity] {
        guard let data = UserDefaults.standard.data(forKey: "balance_accounts"),
              let accounts = try? JSONDecoder().decode([Account].self, from: data)
        else { return [] }
        // Put default account first
        return accounts
            .sorted { $0.isDefault && !$1.isDefault }
            .map { AccountEntity(id: $0.id, name: $0.name) }
    }
}

// MARK: - Quick Transaction Type
enum QuickTransactionType: String, AppEnum {
    case expense = "Expense"
    case income  = "Income"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Transaction Type"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .expense: DisplayRepresentation(title: "Expense", image: .init(systemName: "arrow.up.circle.fill")),
        .income:  DisplayRepresentation(title: "Income",  image: .init(systemName: "arrow.down.circle.fill"))
    ]
}

// MARK: - Quick Add Transaction Intent (Back Tap)
/// Records a transaction without opening the app.
/// Assign to Back Tap via Settings → Accessibility → Touch → Back Tap → Double Tap.
struct QuickAddTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Add Transaction"
    static let description = IntentDescription("Record a transaction without opening Balance")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Amount", requestValueDialog: IntentDialog("How much?"))
    var amount: Double

    @Parameter(title: "Type", requestValueDialog: IntentDialog("Income or expense?"))
    var type: QuickTransactionType

    @Parameter(title: "Account", requestValueDialog: IntentDialog("Which account?"))
    var account: AccountEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$type) of \(\.$amount) to \(\.$account)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults.standard
        let decoder  = JSONDecoder()   // matches ViewModel — no custom date strategy
        let encoder  = JSONEncoder()

        // Resolve account: use selected, then default, then first
        guard let acctData = defaults.data(forKey: "balance_accounts"),
              let allAccounts = try? decoder.decode([Account].self, from: acctData),
              !allAccounts.isEmpty
        else {
            return .result(dialog: "No account found. Open Balance to add an account first.")
        }

        let targetAccount: Account
        if let selectedId = account?.id,
           let found = allAccounts.first(where: { $0.id == selectedId }) {
            targetAccount = found
        } else {
            targetAccount = allAccounts.first(where: { $0.isDefault }) ?? allAccounts[0]
        }

        // Load existing transactions and append
        var transactions: [Transaction] = []
        if let data = defaults.data(forKey: "balance_transactions"),
           let existing = try? decoder.decode([Transaction].self, from: data) {
            transactions = existing
        }

        let txType: TransactionType = type == .income ? .income : .expense
        transactions.append(Transaction(amount: amount, type: txType, accountId: targetAccount.id))

        if let encoded = try? encoder.encode(transactions) {
            defaults.set(encoded, forKey: "balance_transactions")
            defaults.set(Date(), forKey: "balance_transactions_date")
        }

        await MainActor.run {
            NotificationCenter.default.post(name: Notification.Name("BalanceExternalDataChanged"), object: nil)
        }

        var currency = "USD"
        if let stateData = defaults.data(forKey: "balance_appState"),
           let appState = try? decoder.decode(AppState.self, from: stateData) {
            currency = appState.selectedCurrency
        }

        let sign = txType == .income ? "+" : "−"
        return .result(dialog: "\(sign)\(formatCurrency(amount, currency: currency)) recorded in \(targetAccount.name) ✓")
    }
}

// MARK: - App Shortcuts Provider
struct BalanceShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickAddTransactionIntent(),
            phrases: [
                "Add transaction to \(.applicationName)",
                "Quick record in \(.applicationName)",
                "Log transaction in \(.applicationName)"
            ],
            shortTitle: "Quick Add",
            systemImageName: "plus.circle.fill"
        )

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
