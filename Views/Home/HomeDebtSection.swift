import SwiftUI

// MARK: - Home Debt Section
struct HomeDebtSection: View {
    @ObservedObject var viewModel: BalancedViewModel
    @State private var navigateToDebts = false

    private let debtColor = Color(hex: "FF3B30")
    private let incomeColor = Color(hex: "34C759")

    private var topDebts: [Debt] {
        // Overdue first, then by due date
        let active = viewModel.activeDebts
        let overdue = active.filter { $0.isOverdue }
        let rest = active.filter { !$0.isOverdue }.sorted {
            if let d0 = $0.dueDate, let d1 = $1.dueDate { return d0 < d1 }
            if $0.dueDate != nil { return true }
            return $0.createdAt > $1.createdAt
        }
        return Array((overdue + rest).prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(debtColor.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(debtColor)
                    }
                    Text("Debts")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Color(uiColor: .label))
                }
                Spacer()
                Button {
                    navigateToDebts = true
                } label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
            }

            // Summary row
            HStack(spacing: 16) {
                if viewModel.totalOutstandingOwed > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(debtColor)
                        Text("You owe \(formatCurrency(viewModel.totalOutstandingOwed, currency: viewModel.appState.selectedCurrency))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(debtColor)
                    }
                }
                if viewModel.totalOutstandingOwedToMe > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(incomeColor)
                        Text("\(formatCurrency(viewModel.totalOutstandingOwedToMe, currency: viewModel.appState.selectedCurrency)) owed to you")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(incomeColor)
                    }
                }
            }

            // Debt rows
            VStack(spacing: 0) {
                ForEach(Array(topDebts.enumerated()), id: \.element.id) { index, debt in
                    NavigationLink(value: debt) {
                        homeDebtRow(debt)
                    }
                    if index < topDebts.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(12)

            // Overdue warning banner
            if !viewModel.overdueDebts.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(debtColor)
                    Text("\(viewModel.overdueDebts.count) payment\(viewModel.overdueDebts.count == 1 ? "" : "s") overdue — review your debts")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(debtColor)
                    Spacer()
                }
                .padding(10)
                .background(debtColor.opacity(0.08))
                .cornerRadius(10)
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.CornerRadius.large)
        .navigationDestination(for: Debt.self) { debt in
            DebtDetailView(viewModel: viewModel, debt: debt)
        }
        .navigationDestination(isPresented: $navigateToDebts) {
            DebtsListView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func homeDebtRow(_ debt: Debt) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill((debt.type == .iOwe ? debtColor : incomeColor).opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: debt.icon)
                    .font(.system(size: 15))
                    .foregroundColor(debt.type == .iOwe ? debtColor : incomeColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(debt.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                        .lineLimit(1)
                    if debt.isOverdue {
                        Text("OVERDUE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(debtColor)
                            .clipShape(Capsule())
                    }
                }
                if !debt.person.isEmpty {
                    Text(debt.person)
                        .font(.system(size: 11))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }

            Spacer()

            Text(formatCurrency(debt.remaining, currency: viewModel.appState.selectedCurrency))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(debt.type == .iOwe ? debtColor : incomeColor)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(uiColor: .quaternaryLabel))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
