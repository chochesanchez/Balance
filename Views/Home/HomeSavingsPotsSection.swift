import SwiftUI

// MARK: - Savings Pots Summary Section
struct SavingsPotsSummarySection: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var showAddPot = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HomeSectionHeader(title: "Savings Pots") {
                showAddPot = true
            }

            if viewModel.envelopes.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray.2.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.Colors.primary.opacity(0.3))

                    Text("No savings pots yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))

                    Text("Create pots for Savings, Investment, Charity, etc.")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                        .multilineTextAlignment(.center)

                    Button(action: { showAddPot = true }) {
                        Text("Create Pot")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Theme.Colors.primary)
                            .clipShape(Capsule())
                    }
                    .padding(.top, Theme.Spacing.xxs)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(Theme.CornerRadius.large)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.envelopes) { pot in
                            NavigationLink(destination: GoalDetailView(viewModel: viewModel, goal: pot)) {
                                VStack(spacing: Theme.Spacing.xs) {
                                    Image(systemName: pot.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(pot.colorValue)
                                        .frame(width: 40, height: 40)
                                        .background(pot.colorValue.opacity(0.12))
                                        .clipShape(Circle())

                                    Text(formatCurrency(pot.currentAmount, currency: viewModel.appState.selectedCurrency))
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color(uiColor: .label))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)

                                    Text(pot.title)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(uiColor: .secondaryLabel))
                                        .lineLimit(1)
                                }
                                .frame(width: 100)
                                .padding(.vertical, 14)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(14)
                            }
                            .accessibilityLabel("\(pot.title): \(formatCurrency(pot.currentAmount, currency: viewModel.appState.selectedCurrency))")
                        }

                        Button(action: { showAddPot = true }) {
                            VStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                                    .frame(width: 40, height: 40)
                                    .background(Color(uiColor: .tertiarySystemFill))
                                    .clipShape(Circle())

                                Text("$0")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.clear)

                                Text("New Pot")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(uiColor: .secondaryLabel))
                            }
                            .frame(width: 100)
                            .padding(.vertical, 14)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                        .accessibilityLabel("Add new savings pot")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddPot) {
            NavigationStack {
                QuickAddPotSheet(viewModel: viewModel)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Savings Pot Card
struct SavingsPotCard: View {
    let pot: Goal
    let currency: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: pot.icon)
                    .font(.system(size: 18))
                    .foregroundColor(pot.colorValue)
                    .frame(width: 40, height: 40)
                    .background(pot.colorValue.opacity(0.12))
                    .clipShape(Circle())

                Text(formatCurrency(pot.currentAmount, currency: currency))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(uiColor: .label))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(pot.title)
                    .font(.system(size: 11))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .lineLimit(1)
            }
            .frame(width: 100)
            .padding(.vertical, 14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
        .buttonStyle(PressEffectButtonStyle())
        .accessibilityLabel("\(pot.title): \(formatCurrency(pot.currentAmount, currency: currency))")
    }
}

// MARK: - Pot Contribute Sheet
struct PotContributeSheet: View {
    @ObservedObject var viewModel: BalanceViewModel
    let pot: Goal
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var isWithdraw = false
    @State private var selectedAccountId: UUID?
    @FocusState private var isFocused: Bool

    private var currencySymbol: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = viewModel.appState.selectedCurrency
        return f.currencySymbol ?? "$"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: pot.icon)
                    .font(.system(size: 20))
                    .foregroundColor(pot.colorValue)
                    .frame(width: Theme.Sizes.iconLarge, height: Theme.Sizes.iconLarge)
                    .background(pot.colorValue.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(pot.title)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Color(uiColor: .label))

                    Text("Balance: \(formatCurrency(pot.currentAmount, currency: viewModel.appState.selectedCurrency))")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }

                Spacer()
            }
            .padding(.top, Theme.Spacing.xs)

            // Add / Withdraw toggle
            HStack(spacing: 0) {
                Button(action: { withAnimation { isWithdraw = false } }) {
                    Text("Add")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(!isWithdraw ? .white : Color(uiColor: .secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(!isWithdraw ? Theme.Colors.income : Color.clear)
                        .clipShape(Capsule())
                }

                Button(action: { withAnimation { isWithdraw = true } }) {
                    Text("Withdraw")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isWithdraw ? .white : Color(uiColor: .secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(isWithdraw ? Theme.Colors.expense : Color.clear)
                        .clipShape(Capsule())
                }
            }
            .padding(3)
            .background(Color(uiColor: .tertiarySystemFill))
            .clipShape(Capsule())

            // Source account picker
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(isWithdraw ? "RETURN TO" : "FROM ACCOUNT")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(uiColor: .secondaryLabel))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.accounts) { account in
                            let isSelected = selectedAccountId == account.id
                            Button(action: { withAnimation(.snappy) { selectedAccountId = account.id }; Haptics.selection() }) {
                                VStack(spacing: 4) {
                                    Image(systemName: account.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(isSelected ? .white : Color(hex: account.color))
                                        .frame(width: 36, height: 36)
                                        .background(isSelected ? Color(hex: account.color) : Color(hex: account.color).opacity(0.12))
                                        .clipShape(Circle())

                                    Text(account.name)
                                        .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                                        .foregroundColor(isSelected ? Color(uiColor: .label) : Color(uiColor: .secondaryLabel))
                                        .lineLimit(1)
                                }
                                .frame(width: 64)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack(spacing: 4) {
                Text(currencySymbol)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))

                TextField("0", text: $amountText)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color(uiColor: .label))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
            }
            .padding(.horizontal, 40)

            Spacer()

            Button(action: save) {
                Text(isWithdraw ? "Withdraw" : "Add to Pot")
                    .font(Theme.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSave ? (isWithdraw ? Theme.Colors.expense : Theme.Colors.income) : Color(uiColor: .systemGray3))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
            }
            .disabled(!canSave)
            .padding(.bottom, Theme.Spacing.xs)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .onAppear {
            isFocused = true
            selectedAccountId = viewModel.accounts.first?.id
        }
    }

    private var canSave: Bool {
        guard let value = Double(amountText), value > 0, selectedAccountId != nil else { return false }
        return true
    }

    private func save() {
        guard let value = Double(amountText), value > 0 else { return }
        let amount = isWithdraw ? -value : value
        viewModel.contributeToGoal(pot, amount: amount, fromAccountId: selectedAccountId)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Quick Add Pot Sheet
struct QuickAddPotSheet: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = "banknote.fill"
    @State private var selectedColorIndex = 13

    private let potIcons = [
        "banknote.fill", "chart.line.uptrend.xyaxis", "heart.fill", "graduationcap.fill",
        "airplane", "house.fill", "gift.fill", "leaf.fill",
        "star.fill", "target", "car.fill", "laptopcomputer",
        "suitcase.fill", "bag.fill", "creditcard.fill", "wallet.pass.fill",
        "dog.fill", "pawprint.fill", "dumbbell.fill", "camera.fill",
        "crown.fill", "sparkles", "bolt.fill", "moon.fill",
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.md) {
                // Preview
                VStack(spacing: 6) {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 22))
                        .foregroundColor(Theme.Colors.categoryColors[selectedColorIndex])
                        .frame(width: 48, height: 48)
                        .background(Theme.Colors.categoryColors[selectedColorIndex].opacity(0.12))
                        .clipShape(Circle())

                    Text(name.isEmpty ? "Pot Name" : name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(name.isEmpty ? Color(uiColor: .tertiaryLabel) : Color(uiColor: .label))
                }
                .padding(.top, Theme.Spacing.xxs)

                TextField("Name (e.g., Savings, Investment)", text: $name)
                    .font(.system(size: 15))
                    .padding(Theme.Spacing.sm)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .cornerRadius(Theme.CornerRadius.small)

                // Icon picker
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("ICON")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(uiColor: .secondaryLabel))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Theme.Spacing.xs) {
                        ForEach(Array(potIcons.prefix(12)), id: \.self) { icon in
                            IconPickerItem(
                                icon: icon,
                                color: Theme.Colors.categoryColors[selectedColorIndex],
                                isSelected: selectedIcon == icon,
                                action: { selectedIcon = icon; Haptics.selection() }
                            )
                        }
                    }
                }

                // Color picker
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("COLOR")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(uiColor: .secondaryLabel))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: Theme.Spacing.xs) {
                        ForEach(0..<min(16, Theme.Colors.categoryColors.count), id: \.self) { index in
                            ColorPickerItem(
                                color: Theme.Colors.categoryColors[index],
                                isSelected: selectedColorIndex == index,
                                action: { selectedColorIndex = index; Haptics.selection() }
                            )
                        }
                    }
                }

                Button(action: createPot) {
                    Text("Create Pot")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(name.isEmpty ? Color(uiColor: .systemGray3) : Theme.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
                }
                .disabled(name.isEmpty)
                .padding(.top, Theme.Spacing.xxs)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .navigationTitle("New Savings Pot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
    }

    private func createPot() {
        let colorHex = Theme.Colors.categoryColors[selectedColorIndex].toHex() ?? "#007AFF"
        let pot = Goal(
            title: name,
            icon: selectedIcon,
            color: colorHex,
            goalType: .envelope
        )
        viewModel.addGoal(pot)
        Haptics.success()
        dismiss()
    }
}
