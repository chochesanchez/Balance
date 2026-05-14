import SwiftUI

struct GoalCompletionSheet: View {
    @ObservedObject var viewModel: BalancedViewModel
    let goal: Goal
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .markOnly
    @State private var spendAmount: String
    @State private var selectedAccountId: UUID?
    @State private var selectedCategoryId: UUID?
    @FocusState private var amountFocused: Bool

    enum Mode: String, CaseIterable, Identifiable {
        case markOnly = "Mark as Completed"
        case recordPurchase = "Complete & Record Purchase"
        case keepSaving = "Keep Saving"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .markOnly: return "checkmark.seal.fill"
            case .recordPurchase: return "cart.fill"
            case .keepSaving: return "arrow.up.right.circle.fill"
            }
        }

        var subtitle: String {
            switch self {
            case .markOnly: return "Keep the saved amount; no transaction recorded."
            case .recordPurchase: return "Record a real expense from an account."
            case .keepSaving: return "Don't complete yet — keep adding contributions."
            }
        }
    }

    init(viewModel: BalancedViewModel, goal: Goal) {
        self.viewModel = viewModel
        self.goal = goal
        let defaultSpend = goal.targetAmount > 0 ? goal.targetAmount : goal.currentAmount
        _spendAmount = State(initialValue: String(format: "%.2f", defaultSpend))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header

                    VStack(spacing: 10) {
                        ForEach(Mode.allCases) { option in
                            modeRow(option)
                        }
                    }
                    .padding(.horizontal, 20)

                    if mode == .recordPurchase {
                        purchaseDetails
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer(minLength: 12)
                }
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                primaryButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .background(Color(uiColor: .systemBackground).opacity(0.95))
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Goal Reached")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                selectedAccountId = viewModel.accounts.first(where: { $0.isDefault })?.id
                    ?? viewModel.accounts.first?.id
                selectedCategoryId = viewModel.expenseCategories.first?.id
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(goal.colorValue.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: goal.icon)
                    .font(.system(size: 30))
                    .foregroundColor(goal.colorValue)
                    .accessibilityHidden(true)
            }
            Text(goal.title)
                .font(.system(size: 20, weight: .bold))
            Text("You've saved \(formatCurrency(goal.currentAmount, currency: viewModel.appState.selectedCurrency))")
                .font(.system(size: 13))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func modeRow(_ option: Mode) -> some View {
        let selected = mode == option
        Button {
            withAnimation(.snappy) { mode = option }
            Haptics.selection()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(selected ? .white : goal.colorValue)
                    .frame(width: 44, height: 44)
                    .background((selected ? goal.colorValue : goal.colorValue.opacity(0.12)))
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                    Text(option.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(goal.colorValue)
                        .accessibilityHidden(true)
                }
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? goal.colorValue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.rawValue)
        .accessibilityValue(option.subtitle)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private var purchaseDetails: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AMOUNT SPENT")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                HStack {
                    Text(Locale.current.currencySymbol ?? "$")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .accessibilityHidden(true)
                    TextField("0.00", text: $spendAmount)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .focused($amountFocused)
                        .accessibilityLabel("Amount spent in \(viewModel.appState.selectedCurrency)")
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("PAID FROM")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.accounts) { account in
                            let selected = selectedAccountId == account.id
                            Button {
                                withAnimation(.snappy) { selectedAccountId = account.id }
                                Haptics.selection()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: account.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(selected ? .white : account.colorValue)
                                        .frame(width: 44, height: 44)
                                        .background(selected ? account.colorValue : account.colorValue.opacity(0.12))
                                        .clipShape(Circle())
                                        .accessibilityHidden(true)
                                    Text(account.name)
                                        .font(.system(size: 11, weight: selected ? .semibold : .regular))
                                        .foregroundColor(selected ? Color(uiColor: .label) : Color(uiColor: .secondaryLabel))
                                        .lineLimit(1)
                                }
                                .frame(width: 72)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(account.name)
                            .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                }
            }

            if !viewModel.expenseCategories.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CATEGORY (OPTIONAL)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("None").tag(UUID?.none)
                        ForEach(viewModel.expenseCategories) { cat in
                            Text(cat.name).tag(UUID?.some(cat.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }

            Text("This will create a real expense. Money already saved into this goal isn't deducted automatically — pick the actual account you paid from.")
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .padding(.horizontal, 20)
    }

    private var primaryButton: some View {
        Button(action: confirm) {
            Text(primaryButtonTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(canConfirm ? goal.colorValue : goal.colorValue.opacity(0.3))
                .cornerRadius(14)
        }
        .disabled(!canConfirm)
        .accessibilityLabel(primaryButtonTitle)
    }

    private var primaryButtonTitle: String {
        switch mode {
        case .markOnly: return "Mark as Completed"
        case .recordPurchase: return "Complete & Record Purchase"
        case .keepSaving: return "Keep Saving"
        }
    }

    private var canConfirm: Bool {
        switch mode {
        case .markOnly, .keepSaving:
            return true
        case .recordPurchase:
            let value = Double(spendAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
            return value > 0 && selectedAccountId != nil
        }
    }

    private func confirm() {
        switch mode {
        case .markOnly:
            viewModel.markGoalCompleted(goal)
        case .recordPurchase:
            guard let accountId = selectedAccountId,
                  let value = Double(spendAmount.replacingOccurrences(of: ",", with: ".")),
                  value > 0
            else { return }
            viewModel.completeGoalWithPurchase(goal, fromAccountId: accountId, spendAmount: value, categoryId: selectedCategoryId)
        case .keepSaving:
            break
        }
        Haptics.success()
        dismiss()
    }
}
