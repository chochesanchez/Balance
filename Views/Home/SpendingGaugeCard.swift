import SwiftUI

// MARK: - Gauge Scope
enum GaugeScope: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

// MARK: - Spending Gauge Card (Semicircular Arc)
struct SpendingGaugeCard: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Binding var isHidden: Bool
    @State private var animatedProgress: Double = 0
    @State private var scope: GaugeScope = .week
    @State private var showLimitEditor = false

    private var spendingLimit: Double {
        let base = viewModel.appState.weeklySpendingLimit
        switch scope {
        case .day: return base / 7.0
        case .week: return base
        case .month: return base * 4.33
        }
    }

    private var scopeInterval: DateInterval {
        let cal = Calendar.current
        switch scope {
        case .day:
            let start = cal.startOfDay(for: Date())
            let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
            return DateInterval(start: start, end: end)
        case .week:
            return cal.dateInterval(of: .weekOfYear, for: Date()) ?? DateInterval()
        case .month:
            return cal.dateInterval(of: .month, for: Date()) ?? DateInterval()
        }
    }

    private var scopeTransactions: [Transaction] {
        viewModel.transactions.filter { $0.date >= scopeInterval.start && $0.date < scopeInterval.end }
    }

    private var scopeIncome: Double {
        scopeTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var scopeExpenses: Double {
        scopeTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var spentRatio: Double {
        guard spendingLimit > 0 else { return 0 }
        return min(1, scopeExpenses / spendingLimit)
    }

    private var remaining: Double {
        max(0, spendingLimit - scopeExpenses)
    }

    private var remainingRatio: Double {
        guard spendingLimit > 0 else { return 1 }
        return max(0, 1.0 - spentRatio)
    }

    private var gaugeColor: Color {
        if spendingLimit <= 0 { return Theme.Colors.primary }
        let left = remainingRatio
        if left > 0.3 { return Theme.Colors.primary }
        if left > 0.1 { return Theme.Colors.recurring }
        return Theme.Colors.expense
    }

    private var scopeLabel: String {
        switch scope {
        case .day: return "today"
        case .week: return "this week"
        case .month: return "this month"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: scope picker + eye toggle
            HStack {
                HStack(spacing: 4) {
                    ForEach(GaugeScope.allCases, id: \.self) { s in
                        Button(action: {
                            withAnimation(.snappy(duration: 0.3)) { scope = s }
                            Haptics.selection()
                        }) {
                            Text(s.rawValue)
                                .font(.system(size: 12, weight: scope == s ? .semibold : .regular))
                                .foregroundColor(scope == s ? .white : Color(uiColor: .secondaryLabel))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(scope == s ? Theme.Colors.primary : Color.clear)
                                .clipShape(Capsule())
                        }
                        .accessibilityLabel("\(s.rawValue) view")
                    }
                }
                .padding(3)
                .background(Color(uiColor: .tertiarySystemFill))
                .clipShape(Capsule())

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) { isHidden = true }
                    Haptics.light()
                }) {
                    Image(systemName: "eye")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .accessibilityLabel("Hide balance")
            }
            .padding(.bottom, Theme.Spacing.md)

            // Semicircular gauge
            ZStack {
                SemiCircleArc(progress: 1.0)
                    .stroke(Color(uiColor: .tertiarySystemFill), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 200, height: 100)

                SemiCircleArc(progress: animatedProgress)
                    .stroke(
                        gaugeColor.opacity(0.85),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 200, height: 100)
                    .shadow(color: gaugeColor.opacity(0.25), radius: 8, y: 2)

                // Center content
                VStack(spacing: 2) {
                    if spendingLimit > 0 {
                        Text(formatCurrency(scopeExpenses, currency: viewModel.appState.selectedCurrency))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(uiColor: .label))
                            .contentTransition(.numericText(value: scopeExpenses))
                            .animation(.snappy, value: scopeExpenses)
                            .accessibilityLabel("Spent \(scopeLabel)")
                            .accessibilityValue(formatCurrency(scopeExpenses, currency: viewModel.appState.selectedCurrency))

                        Text("of \(formatCompactAmount(spendingLimit, currency: viewModel.appState.selectedCurrency)) \(scopeLabel)")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    } else {
                        Text(formatCurrency(scopeExpenses, currency: viewModel.appState.selectedCurrency))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(uiColor: .label))
                            .contentTransition(.numericText(value: scopeExpenses))
                            .animation(.snappy, value: scopeExpenses)
                            .accessibilityLabel("Spent \(scopeLabel)")
                            .accessibilityValue(formatCurrency(scopeExpenses, currency: viewModel.appState.selectedCurrency))

                        Text("spent \(scopeLabel)")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
                .offset(y: 16)
            }
            .frame(height: 130)
            .padding(.bottom, Theme.Spacing.xs)

            // Spending limit pill (tap to set/edit)
            Button(action: {
                showLimitEditor = true
                Haptics.light()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .medium))

                    if viewModel.appState.weeklySpendingLimit > 0 {
                        Text("\(formatCompactAmount(remaining, currency: viewModel.appState.selectedCurrency)) left \(scopeLabel)")
                            .font(.system(size: 12, weight: .medium))
                    } else {
                        Text("Set spending limit")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .foregroundColor(Theme.Colors.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Theme.Colors.primary.opacity(0.08))
                .clipShape(Capsule())
            }
            .accessibilityLabel(viewModel.appState.weeklySpendingLimit > 0 ? "Edit spending limit" : "Set spending limit")
            .padding(.bottom, 14)

            // Divider
            Rectangle()
                .fill(Color(uiColor: .separator).opacity(0.5))
                .frame(height: 0.5)
                .padding(.horizontal, 4)
                .padding(.bottom, 14)

            // Income & Expenses
            HStack(spacing: 0) {
                GaugeStatView(
                    icon: "arrow.down",
                    label: "Income",
                    value: scopeIncome,
                    color: Theme.Colors.income,
                    currency: viewModel.appState.selectedCurrency
                )

                Rectangle()
                    .fill(Color(uiColor: .separator))
                    .frame(width: 0.5, height: 32)

                GaugeStatView(
                    icon: "arrow.up",
                    label: "Spent",
                    value: scopeExpenses,
                    color: Theme.Colors.expense,
                    currency: viewModel.appState.selectedCurrency
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.CornerRadius.large)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .onAppear { animateGauge() }
        .onChange(of: spentRatio) { _, _ in animateGauge() }
        .onChange(of: scope) { _, _ in animateGauge() }
        .sheet(isPresented: $showLimitEditor) {
            SpendingLimitEditor(viewModel: viewModel)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }

    private func animateGauge() {
        withAnimation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.1)) {
            animatedProgress = spendingLimit > 0 ? remainingRatio : 1.0
        }
    }
}

// MARK: - Spending Limit Editor Sheet
struct SpendingLimitEditor: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var limitText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Weekly Spending Limit")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))

                    Text("Set how much you want to spend per week. We'll track your progress and adapt daily/monthly views automatically.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.top, Theme.Spacing.xs)

                HStack(spacing: 4) {
                    Text(currencySymbol)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))

                    TextField("0", text: $limitText)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .focused($isFocused)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)

                HStack(spacing: 10) {
                    ForEach(suggestedLimits, id: \.self) { amount in
                        Button(action: {
                            limitText = "\(Int(amount))"
                            Haptics.selection()
                        }) {
                            Text(formatCompactAmount(amount, currency: viewModel.appState.selectedCurrency))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.Colors.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Theme.Colors.primary.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Button(action: save) {
                    Text("Save")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xs)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }
        }
        .onAppear {
            let current = viewModel.appState.weeklySpendingLimit
            limitText = current > 0 ? "\(Int(current))" : ""
            isFocused = true
        }
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.appState.selectedCurrency
        return formatter.currencySymbol ?? "$"
    }

    private var suggestedLimits: [Double] {
        let avgWeeklyExpense = viewModel.currentRangeExpenses
        if avgWeeklyExpense > 100 {
            let rounded = (avgWeeklyExpense / 100).rounded() * 100
            return [rounded * 0.5, rounded, rounded * 1.5]
        }
        return [500, 1000, 2000]
    }

    // FIX B3: Locale-aware parsing replaces plain Double(limitText)
    private func save() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        let value = formatter.number(from: limitText)?.doubleValue
                   ?? Double(limitText.replacingOccurrences(of: ",", with: "."))
                   ?? 0
        viewModel.appState.weeklySpendingLimit = max(0, value)
        viewModel.saveData()
        Haptics.success()
        dismiss()
    }
}

// MARK: - Semicircle Arc Shape
struct SemiCircleArc: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width / 2, rect.height)
        let startAngle = Angle.degrees(180)
        let endAngle = Angle.degrees(180 + (180 * progress))

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

// MARK: - Gauge Stat View
struct GaugeStatView: View {
    let icon: String
    let label: String
    let value: Double
    let color: Color
    let currency: String

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 26, height: 26)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Color(uiColor: .secondaryLabel))

                Text(formatCompactAmount(value, currency: currency))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
                    .contentTransition(.numericText(value: value))
                    .animation(.snappy, value: value)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(formatCurrency(value, currency: currency))")
    }
}

// MARK: - Balance Hidden Pill
struct BalanceHiddenPill: View {
    @Binding var isHidden: Bool

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) { isHidden = false }
            Haptics.light()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "eye.slash")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))

                Text("Balance hidden")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: .secondaryLabel))

                Spacer()

                Text("Tap to show")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(Theme.CornerRadius.large)
        }
        .accessibilityLabel("Balance hidden. Tap to show.")
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
