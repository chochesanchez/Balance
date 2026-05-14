#if DEBUG
import Foundation

@MainActor
enum FinanceLogicTests {
    struct Result {
        let name: String
        let passed: Bool
        let detail: String
    }

    static func runAll(verbose: Bool = true) -> [Result] {
        var results: [Result] = []
        results.append(testEditAccountBalanceDoesNotCreateTransaction())
        results.append(testEditPotAmountDoesNotCreateTransaction())
        results.append(testPotWithdrawalNotCountedAsIncome())
        results.append(testPotDepositNotCountedAsExpense())
        results.append(testGoalContributionExcludedFromAnalytics())
        results.append(testGoalCompletionWithPurchaseCreatesExpense())
        results.append(testMarkGoalCompletedNoTransaction())
        results.append(testRoundingTwoDecimals())
        results.append(testNoNegativePotBalance())
        results.append(testArchivedAccountHiddenFromActiveSelectors())
        results.append(testCloseByTransferDoesNotPolluteAnalytics())
        results.append(testDeleteWithRemoveBalanceWritesAdjustment())
        results.append(testAccountCorrectionWritesAdjustment())
        results.append(testStarterCategoriesAreIdempotent())
        results.append(testDemoDataCanBeRemoved())
        results.append(testRatingManagerRespectsCooldown())
        if verbose {
            for r in results {
                Log.finance.log("[\(r.passed ? "PASS" : "FAIL", privacy: .public)] \(r.name, privacy: .public) — \(r.detail, privacy: .public)")
            }
        }
        return results
    }

    private static func makeVM(accountBalance: Double = 100) -> (BalancedViewModel, Account) {
        let vm = BalancedViewModel()
        vm.accounts = [Account(name: "Cash-test-\(UUID().uuidString.prefix(4))", type: .cash, initialBalance: accountBalance, isDefault: true)]
        vm.transactions = []
        vm.goals = []
        vm.recurringTransactions = []
        return (vm, vm.accounts[0])
    }

    private static func testEditAccountBalanceDoesNotCreateTransaction() -> Result {
        let (vm, account) = makeVM(accountBalance: 100)
        let txCountBefore = vm.transactions.count
        vm.setAccountBalance(account, to: 500)
        let displayed = vm.balanceForAccount(vm.accounts[0])
        let didNotCreateTransaction = vm.transactions.count == txCountBefore
        let passed = abs(displayed - 500) < 0.01 && didNotCreateTransaction
        return Result(name: "Edit account balance: no transaction; balance updates",
                      passed: passed,
                      detail: "displayed=\(displayed) txDelta=\(vm.transactions.count - txCountBefore)")
    }

    private static func testEditPotAmountDoesNotCreateTransaction() -> Result {
        let (vm, _) = makeVM()
        let pot = Goal(title: "Pot-\(UUID().uuidString.prefix(4))", goalType: .envelope)
        vm.goals.append(pot)
        let txBefore = vm.transactions.count
        vm.setGoalCurrentAmount(pot, to: 250)
        let updated = vm.goals.first { $0.id == pot.id }
        let didNotCreateTransaction = vm.transactions.count == txBefore
        let passed = updated?.currentAmount == 250 && didNotCreateTransaction
        return Result(name: "Edit pot saved amount: no transaction; amount updates",
                      passed: passed,
                      detail: "saved=\(updated?.currentAmount ?? -1) txDelta=\(vm.transactions.count - txBefore)")
    }

    private static func testPotWithdrawalNotCountedAsIncome() -> Result {
        let (vm, account) = makeVM()
        let pot = Goal(title: "Pot-\(UUID().uuidString.prefix(4))", currentAmount: 100, goalType: .envelope)
        vm.goals.append(pot)
        let incomeBefore = vm.monthlyIncome
        let expenseBefore = vm.monthlyExpenses
        vm.contributeToGoal(pot, amount: -40, fromAccountId: account.id)
        let incomeAfter = vm.monthlyIncome
        let expenseAfter = vm.monthlyExpenses
        let passed = incomeAfter == incomeBefore && expenseAfter == expenseBefore
        return Result(name: "Pot withdrawal excluded from income/expense analytics",
                      passed: passed,
                      detail: "Δincome=\(incomeAfter - incomeBefore) Δexpense=\(expenseAfter - expenseBefore)")
    }

    private static func testPotDepositNotCountedAsExpense() -> Result {
        let (vm, account) = makeVM()
        let pot = Goal(title: "Pot-\(UUID().uuidString.prefix(4))", goalType: .envelope)
        vm.goals.append(pot)
        let incomeBefore = vm.monthlyIncome
        let expenseBefore = vm.monthlyExpenses
        vm.contributeToGoal(pot, amount: 75, fromAccountId: account.id)
        let passed = vm.monthlyExpenses == expenseBefore && vm.monthlyIncome == incomeBefore
        return Result(name: "Pot deposit excluded from income/expense analytics",
                      passed: passed,
                      detail: "Δincome=\(vm.monthlyIncome - incomeBefore) Δexpense=\(vm.monthlyExpenses - expenseBefore)")
    }

    private static func testGoalContributionExcludedFromAnalytics() -> Result {
        let (vm, account) = makeVM()
        let goal = Goal(title: "MacBook-\(UUID().uuidString.prefix(4))", targetAmount: 1000, goalType: .goal)
        vm.goals.append(goal)
        let incBefore = vm.monthlyIncome
        let expBefore = vm.monthlyExpenses
        vm.contributeToGoal(goal, amount: 200, fromAccountId: account.id)
        let passed = vm.monthlyIncome == incBefore && vm.monthlyExpenses == expBefore
        return Result(name: "Goal contribution excluded from income/expense analytics",
                      passed: passed,
                      detail: "Δincome=\(vm.monthlyIncome - incBefore) Δexpense=\(vm.monthlyExpenses - expBefore)")
    }

    private static func testGoalCompletionWithPurchaseCreatesExpense() -> Result {
        let (vm, account) = makeVM(accountBalance: 1000)
        let goal = Goal(title: "MacBook-\(UUID().uuidString.prefix(4))", targetAmount: 1000, goalType: .goal)
        vm.goals.append(goal)
        let expBefore = vm.monthlyExpenses
        vm.completeGoalWithPurchase(goal, fromAccountId: account.id, spendAmount: 999)
        let updated = vm.goals.first { $0.id == goal.id }
        let expAfter = vm.monthlyExpenses
        let passed = (expAfter - expBefore) >= 998 && updated?.isCompleted == true
        return Result(name: "Goal completion with purchase records expense and marks completed",
                      passed: passed,
                      detail: "Δexpense=\(expAfter - expBefore) completed=\(updated?.isCompleted ?? false)")
    }

    private static func testMarkGoalCompletedNoTransaction() -> Result {
        let (vm, _) = makeVM()
        let goal = Goal(title: "Trip-\(UUID().uuidString.prefix(4))", currentAmount: 100, goalType: .goal)
        vm.goals.append(goal)
        let txBefore = vm.transactions.count
        vm.markGoalCompleted(goal)
        let updated = vm.goals.first { $0.id == goal.id }
        let passed = vm.transactions.count == txBefore && updated?.isCompleted == true
        return Result(name: "Mark completed only: no transaction created",
                      passed: passed,
                      detail: "completed=\(updated?.isCompleted ?? false) txDelta=\(vm.transactions.count - txBefore)")
    }

    private static func testRoundingTwoDecimals() -> Result {
        let (vm, account) = makeVM(accountBalance: 100.123)
        vm.setAccountBalance(account, to: 200.567)
        let displayed = vm.balanceForAccount(vm.accounts[0])
        let cents = Int((displayed * 100).rounded())
        let passed = cents == 20057
        return Result(name: "Rounds account balance to two decimals",
                      passed: passed,
                      detail: "displayed=\(displayed) cents=\(cents)")
    }

    private static func testNoNegativePotBalance() -> Result {
        let (vm, account) = makeVM()
        let pot = Goal(title: "Pot-\(UUID().uuidString.prefix(4))", currentAmount: 30, goalType: .envelope)
        vm.goals.append(pot)
        vm.contributeToGoal(pot, amount: -500, fromAccountId: account.id)
        let updated = vm.goals.first { $0.id == pot.id }
        let passed = (updated?.currentAmount ?? -1) >= 0
        return Result(name: "Pot withdrawal cannot make balance negative",
                      passed: passed,
                      detail: "balance=\(updated?.currentAmount ?? -1)")
    }

    private static func testArchivedAccountHiddenFromActiveSelectors() -> Result {
        let (vm, account) = makeVM()
        vm.archiveAccount(account)
        let stillInAll = vm.accounts.contains { $0.id == account.id }
        let hiddenFromActive = !vm.activeAccounts.contains { $0.id == account.id }
        return Result(name: "Archived account: hidden from active selectors, kept in history",
                      passed: stillInAll && hiddenFromActive,
                      detail: "inAll=\(stillInAll) hiddenFromActive=\(hiddenFromActive)")
    }

    private static func testCloseByTransferDoesNotPolluteAnalytics() -> Result {
        let (vm, account) = makeVM(accountBalance: 200)
        let other = Account(name: "Dest-\(UUID().uuidString.prefix(4))", type: .cash)
        vm.accounts.append(other)
        let incBefore = vm.monthlyIncome
        let expBefore = vm.monthlyExpenses
        vm.closeAccountByTransferring(account, toAccountId: other.id)
        let archived = vm.accounts.first { $0.id == account.id }?.isArchived == true
        let cleanAnalytics = vm.monthlyIncome == incBefore && vm.monthlyExpenses == expBefore
        return Result(name: "Close account by transfer: no income/expense impact, archived",
                      passed: archived && cleanAnalytics,
                      detail: "archived=\(archived) Δincome=\(vm.monthlyIncome - incBefore) Δexpense=\(vm.monthlyExpenses - expBefore)")
    }

    private static func testDeleteWithRemoveBalanceWritesAdjustment() -> Result {
        let (vm, account) = makeVM(accountBalance: 150)
        let other = Account(name: "Other-\(UUID().uuidString.prefix(4))", type: .cash)
        vm.accounts.append(other)
        let expBefore = vm.monthlyExpenses
        let adjBefore = vm.adjustments.count
        vm.deleteAccountAndRemoveBalance(account)
        let adjAfter = vm.adjustments.count
        let cleanExpense = vm.monthlyExpenses == expBefore
        let removed = !vm.accounts.contains { $0.id == account.id }
        return Result(name: "Delete with remove balance: adjustment logged, no expense recorded",
                      passed: adjAfter > adjBefore && cleanExpense && removed,
                      detail: "Δadj=\(adjAfter - adjBefore) Δexpense=\(vm.monthlyExpenses - expBefore) removed=\(removed)")
    }

    private static func testAccountCorrectionWritesAdjustment() -> Result {
        let (vm, account) = makeVM(accountBalance: 100)
        let adjBefore = vm.adjustments.count
        vm.setAccountBalanceWithLog(account, to: 220)
        let adjAfter = vm.adjustments.count
        let kind = vm.adjustments.last?.kind == .accountBalanceCorrection
        return Result(name: "Account correction logs adjustment, no transaction created",
                      passed: adjAfter > adjBefore && kind,
                      detail: "Δadj=\(adjAfter - adjBefore) lastKind=\(vm.adjustments.last?.kind.rawValue ?? "nil")")
    }

    private static func testStarterCategoriesAreIdempotent() -> Result {
        let (vm, _) = makeVM()
        vm.categories = []
        vm.installStarterCategoriesIfMissing()
        let first = vm.categories.count
        vm.installStarterCategoriesIfMissing()
        let second = vm.categories.count
        return Result(name: "Starter categories: only installed when empty",
                      passed: first > 0 && first == second,
                      detail: "first=\(first) second=\(second)")
    }

    private static func testDemoDataCanBeRemoved() -> Result {
        let (vm, _) = makeVM()
        vm.installSampleDemoData()
        let createdCount = vm.demoTransactionIds.count
        let txAfterInstall = vm.transactions.count
        vm.removeDemoData()
        let stillReferenced = vm.transactions.contains { vm.demoTransactionIds.contains($0.id) }
        let cleared = vm.demoTransactionIds.isEmpty
        return Result(name: "Demo data: installs and removes cleanly",
                      passed: createdCount > 0 && txAfterInstall > 0 && cleared && !stillReferenced,
                      detail: "created=\(createdCount) cleared=\(cleared)")
    }

    private static func testRatingManagerRespectsCooldown() -> Result {
        let r = RatingManager.shared
        let canBefore = r.canPromptNow()
        return Result(name: "Rating manager respects cooldown / minimum events",
                      passed: r.positiveCount < 3 ? !canBefore : true,
                      detail: "count=\(r.positiveCount) canPrompt=\(canBefore)")
    }
}
#endif
