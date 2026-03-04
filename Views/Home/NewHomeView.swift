import SwiftUI

// MARK: - Home View
struct NewHomeView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var showingRecordSheet = false
    @State private var recordInitialType: TransactionType? = nil
    @State private var recordInitialIsRecurring = false
    @State private var balanceHidden = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HomeHeader(viewModel: viewModel)

                // 1. Spending Gauge
                if !balanceHidden {
                    SpendingGaugeCard(viewModel: viewModel, isHidden: $balanceHidden)
                } else {
                    BalanceHiddenPill(isHidden: $balanceHidden)
                }

                // 2. Quick Actions
                HomeSectionHeader(title: "Quick Actions")
                QuickActionsRow(
                    onAction: { type in
                        recordInitialType = type
                        recordInitialIsRecurring = false
                        showingRecordSheet = true
                    },
                    onRecurring: {
                        recordInitialType = .expense
                        recordInitialIsRecurring = true
                        showingRecordSheet = true
                    }
                )

                // 3. My Accounts
                AccountsSection(viewModel: viewModel)

                // 4. Money Distribution
                MoneyDistributionCard(viewModel: viewModel)

                // 5. Savings Pots (envelopes)
                SavingsPotsSummarySection(viewModel: viewModel)

                // 6. Balance Trend (weekly chart)
                WeeklyBalanceChart(viewModel: viewModel)

                // 7. Calendar
                HomeCalendarSection(viewModel: viewModel)

                // 8. Goals
                GoalsSummarySection(viewModel: viewModel)

                // 9. Recurring
                RecurringSummarySection(viewModel: viewModel)

                // 10. Daily Tips
                DailyTipsSection()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.xs)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .refreshable { viewModel.checkAndProcessRecurring() }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showingRecordSheet) {
            NavigationStack {
                RecordView(
                    viewModel: viewModel,
                    initialType: recordInitialType,
                    initialIsRecurring: recordInitialIsRecurring
                )
            }
        }
    }
}

#Preview {
    MainTabView(viewModel: BalanceViewModel())
}
