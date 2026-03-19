import SwiftUI

// MARK: - Debts List View
struct DebtsListView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var selectedSegment: DebtType = .iOwe
    @State private var showingAdd = false
    @State private var showSettled = false

    private let debtColor = Color(hex: "FF3B30")
    private let incomeColor = Color(hex: "34C759")

    private var filteredActive: [Debt] {
        viewModel.activeDebts.filter { $0.type == selectedSegment }
            .sorted {
                if $0.isOverdue != $1.isOverdue { return $0.isOverdue }
                if let d0 = $0.dueDate, let d1 = $1.dueDate { return d0 < d1 }
                return $0.createdAt > $1.createdAt
            }
    }

    private var filteredSettled: [Debt] {
        viewModel.debts.filter { $0.isSettled && $0.type == selectedSegment }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                summaryHeader
                if !viewModel.debtRecommendations.isEmpty {
                    recommendationsSection
                }
                segmentPicker
                if filteredActive.isEmpty {
                    emptyState
                } else {
                    activeList
                }
                if !filteredSettled.isEmpty {
                    settledSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Debts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAdd = true
                    Haptics.light()
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(debtColor)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddDebtView(viewModel: viewModel)
        }
    }

    // MARK: - Summary Header
    private var summaryHeader: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "I Owe",
                amount: viewModel.totalOutstandingOwed,
                icon: "arrow.up.circle.fill",
                color: debtColor
            )
            summaryCard(
                title: "Owed to Me",
                amount: viewModel.totalOutstandingOwedToMe,
                icon: "arrow.down.circle.fill",
                color: incomeColor
            )
        }
    }

    @ViewBuilder
    private func summaryCard(title: String, amount: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
            Text(formatCurrency(amount, currency: viewModel.appState.selectedCurrency))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(amount > 0 ? color : Color(uiColor: .tertiaryLabel))
                .contentTransition(.numericText(value: amount))
                .animation(.snappy, value: amount)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    // MARK: - Recommendations
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECOMMENDATIONS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .padding(.horizontal, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.debtRecommendations) { rec in
                        HStack(spacing: 8) {
                            Image(systemName: rec.icon)
                                .font(.system(size: 13))
                                .foregroundColor(rec.severity == .warning ? debtColor : rec.severity == .positive ? incomeColor : Theme.Colors.primary)
                            Text(rec.message)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(uiColor: .label))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                    }
                }
            }
        }
    }

    // MARK: - Segment Picker
    private var segmentPicker: some View {
        Picker("Type", selection: $selectedSegment) {
            ForEach(DebtType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Active list
    private var activeList: some View {
        VStack(spacing: 0) {
            ForEach(Array(filteredActive.enumerated()), id: \.element.id) { index, debt in
                NavigationLink(destination: DebtDetailView(viewModel: viewModel, debt: debt)) {
                    DebtRowView(debt: debt, currency: viewModel.appState.selectedCurrency)
                }

                if index < filteredActive.count - 1 {
                    Divider().padding(.leading, 68)
                }
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 36))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
            Text("No \(selectedSegment.rawValue) debts")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Text(selectedSegment == .iOwe ? "Tap + to add money you owe" : "Tap + to track money owed to you")
                .font(.system(size: 13))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .multilineTextAlignment(.center)
            Button {
                showingAdd = true
                Haptics.light()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Debt")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(debtColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    // MARK: - Settled Section
    private var settledSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.snappy) { showSettled.toggle() }
            } label: {
                HStack {
                    Text("\(filteredSettled.count) settled")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    Spacer()
                    Image(systemName: showSettled ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .padding(.horizontal, 4)
            }

            if showSettled {
                VStack(spacing: 0) {
                    ForEach(Array(filteredSettled.enumerated()), id: \.element.id) { index, debt in
                        NavigationLink(destination: DebtDetailView(viewModel: viewModel, debt: debt)) {
                            DebtRowView(debt: debt, currency: viewModel.appState.selectedCurrency)
                                .opacity(0.6)
                        }
                        if index < filteredSettled.count - 1 {
                            Divider().padding(.leading, 68)
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(14)
            }
        }
    }
}

// MARK: - Debt Row View
struct DebtRowView: View {
    let debt: Debt
    let currency: String

    private let debtColor = Color(hex: "FF3B30")
    private let incomeColor = Color(hex: "34C759")

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((debt.isSettled ? incomeColor : debt.type == .iOwe ? debtColor : incomeColor).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: debt.isSettled ? "checkmark.seal.fill" : debt.icon)
                    .font(.system(size: 18))
                    .foregroundColor(debt.isSettled ? incomeColor : debt.type == .iOwe ? debtColor : incomeColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(debt.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                        .strikethrough(debt.isSettled)
                    if debt.isOverdue {
                        Text("OVERDUE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(debtColor)
                            .clipShape(Capsule())
                    }
                }
                if !debt.person.isEmpty {
                    Text(debt.person)
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(debt.remaining, currency: currency))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(debt.isSettled ? incomeColor : debt.type == .iOwe ? debtColor : incomeColor)
                Text("of \(formatCurrency(debt.totalAmount, currency: currency))")
                    .font(.system(size: 11))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(uiColor: .quaternaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
