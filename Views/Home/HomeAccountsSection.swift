import SwiftUI

// MARK: - Accounts Section
struct AccountsSection: View {
    @ObservedObject var viewModel: BalanceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("My Accounts")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Color(uiColor: .label))

                Spacer()

                NavigationLink(destination: WalletView(viewModel: viewModel)) {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
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
                        VStack(spacing: Theme.Spacing.xs) {
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
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    .accessibilityLabel("Add account")
                }
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

// MARK: - Account Card
struct AccountCard: View {
    let account: Account
    let balance: Double
    let currency: String

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
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
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name): \(formatCurrency(balance, currency: currency))")
    }
}

// MARK: - Money Distribution Card
struct MoneyDistributionCard: View {
    @ObservedObject var viewModel: BalanceViewModel

    private struct DistributionItem: Identifiable {
        let id: UUID
        let name: String
        let icon: String
        let color: Color
        let amount: Double
        let isEnvelope: Bool
    }

    private var items: [DistributionItem] {
        var result: [DistributionItem] = viewModel.accounts.map { acct in
            DistributionItem(
                id: acct.id,
                name: acct.name,
                icon: acct.icon,
                color: acct.colorValue,
                amount: viewModel.balanceForAccount(acct),
                isEnvelope: false
            )
        }

        for pot in viewModel.envelopes where pot.currentAmount > 0 {
            result.append(DistributionItem(
                id: pot.id,
                name: pot.title,
                icon: pot.icon,
                color: pot.colorValue,
                amount: pot.currentAmount,
                isEnvelope: true
            ))
        }
        return result
    }

    private var total: Double {
        items.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Money Distribution")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Color(uiColor: .label))

                Spacer()

                Text(formatCurrency(total, currency: viewModel.appState.selectedCurrency))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(uiColor: .label))
                    .contentTransition(.numericText(value: total))
                    .animation(.snappy, value: total)
                    .accessibilityLabel("Total")
                    .accessibilityValue(formatCurrency(total, currency: viewModel.appState.selectedCurrency))
            }

            if total > 0 {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(items.filter { $0.amount > 0 }) { item in
                            let proportion = max(0.02, item.amount / total)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.color)
                                .frame(width: max(6, geo.size.width * proportion - 2))
                        }
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())
                .accessibilityHidden(true)
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(height: 8)
            }

            VStack(spacing: Theme.Spacing.xs) {
                ForEach(items) { item in
                    HStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)

                        Text(item.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(uiColor: .label))

                        if item.isEnvelope {
                            Text("Pot")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.Colors.goals)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.goals.opacity(0.12))
                                .cornerRadius(4)
                        }

                        Spacer()

                        if total > 0 {
                            Text("\(Int((item.amount / total) * 100))%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.name)\(item.isEnvelope ? " (Pot)" : ""): \(total > 0 ? "\(Int((item.amount / total) * 100))%" : "")")
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.CornerRadius.large)
    }
}
