import SwiftUI
import Charts

// MARK: - Home View
struct NewHomeView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var showingRecordSheet = false
    @State private var recordInitialType: TransactionType? = nil
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
                QuickActionsRow(onAction: { type in
                    recordInitialType = type
                    showingRecordSheet = true
                })
                
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .refreshable { viewModel.checkAndProcessRecurring() }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showingRecordSheet) {
            NavigationStack {
                RecordView(viewModel: viewModel, initialType: recordInitialType)
            }
        }
    }
}

// MARK: - Section Header
struct HomeSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(uiColor: .label))
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Header
struct HomeHeader: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    var body: some View {
        NavigationLink(destination: ProfileDetailView(viewModel: viewModel)) {
            HStack(spacing: 12) {
                ProfileAvatarView(imageData: viewModel.userProfile.profileImageData, size: 40)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Welcome")
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Text(viewModel.userProfile.name.isEmpty ? "Balance" : viewModel.userProfile.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

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
            }
            .padding(.bottom, 16)
            
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
                        
                        Text("of \(formatCompactAmount(spendingLimit, currency: viewModel.appState.selectedCurrency)) \(scopeLabel)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    } else {
                        Text(formatCurrency(scopeExpenses, currency: viewModel.appState.selectedCurrency))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(uiColor: .label))
                            .contentTransition(.numericText(value: scopeExpenses))
                            .animation(.snappy, value: scopeExpenses)
                        
                        Text("spent \(scopeLabel)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
                .offset(y: 16)
            }
            .frame(height: 130)
            .padding(.bottom, 8)
            
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
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
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
                VStack(spacing: 8) {
                    Text("Weekly Spending Limit")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text("Set how much you want to spend per week. We'll track your progress and adapt daily/monthly views automatically.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.top, 8)
                
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
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
    
    private func save() {
        let value = Double(limitText) ?? 0
        viewModel.appState.weeklySpendingLimit = value
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
        HStack(spacing: 8) {
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
    }
}

// MARK: - Compact Amount Formatter
func formatCompactAmount(_ amount: Double, currency: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: amount)) ?? "$0"
}

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
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(14)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Quick Actions
struct QuickActionsRow: View {
    let onAction: (TransactionType) -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            QuickActionButton(icon: "arrow.down", label: "Income", color: Theme.Colors.income) {
                onAction(.income)
            }
            QuickActionButton(icon: "arrow.up", label: "Expense", color: Theme.Colors.expense) {
                onAction(.expense)
            }
            QuickActionButton(icon: "arrow.left.arrow.right", label: "Transfer", color: Theme.Colors.primary) {
                onAction(.transfer)
            }
            QuickActionButton(icon: "repeat", label: "Recurring", color: Theme.Colors.recurring) {
                onAction(.expense)
            }
        }
        .padding(14)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            Haptics.light()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 42, height: 42)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(uiColor: .label))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

// MARK: - Savings Pots (Envelopes)
struct SavingsPotsSummarySection: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var selectedPot: Goal? = nil
    @State private var showAddPot = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                        .font(.system(size: 12))
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
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.envelopes) { pot in
                            SavingsPotCard(pot: pot, currency: viewModel.appState.selectedCurrency) {
                                selectedPot = pot
                            }
                        }
                        
                        Button(action: { showAddPot = true }) {
                            VStack(spacing: 8) {
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
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(14)
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedPot) { pot in
            PotContributeSheet(viewModel: viewModel, pot: pot)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddPot) {
            NavigationStack {
                QuickAddPotSheet(viewModel: viewModel)
            }
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.visible)
        }
    }
}

struct SavingsPotCard: View {
    let pot: Goal
    let currency: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
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
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(14)
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

// MARK: - Pot Contribute Sheet
struct PotContributeSheet: View {
    @ObservedObject var viewModel: BalanceViewModel
    let pot: Goal
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var isWithdraw = false
    @FocusState private var isFocused: Bool
    
    private var currencySymbol: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = viewModel.appState.selectedCurrency
        return f.currencySymbol ?? "$"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: pot.icon)
                    .font(.system(size: 20))
                    .foregroundColor(pot.colorValue)
                    .frame(width: 44, height: 44)
                    .background(pot.colorValue.opacity(0.12))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(pot.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text("Balance: \(formatCurrency(pot.currentAmount, currency: viewModel.appState.selectedCurrency))")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                
                Spacer()
            }
            .padding(.top, 8)
            
            // Add / Withdraw toggle
            HStack(spacing: 0) {
                Button(action: { withAnimation { isWithdraw = false } }) {
                    Text("Add")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(!isWithdraw ? .white : Color(uiColor: .secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(!isWithdraw ? Theme.Colors.income : Color.clear)
                        .clipShape(Capsule())
                }
                
                Button(action: { withAnimation { isWithdraw = true } }) {
                    Text("Withdraw")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isWithdraw ? .white : Color(uiColor: .secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isWithdraw ? Theme.Colors.expense : Color.clear)
                        .clipShape(Capsule())
                }
            }
            .padding(3)
            .background(Color(uiColor: .tertiarySystemFill))
            .clipShape(Capsule())
            
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isWithdraw ? Theme.Colors.expense : Theme.Colors.income)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .onAppear { isFocused = true }
    }
    
    private func save() {
        guard let value = Double(amountText), value > 0 else { return }
        let amount = isWithdraw ? -value : value
        viewModel.contributeToGoal(pot, amount: amount)
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
    @State private var selectedColor = "#007AFF"
    
    private let icons = ["banknote.fill", "chart.line.uptrend.xyaxis", "heart.fill", "graduationcap.fill", "airplane", "house.fill", "gift.fill", "leaf.fill"]
    private let colors = ["#007AFF", "#34C759", "#FF9500", "#AF52DE", "#FF2D55", "#5856D6", "#00C7BE", "#FFCC00"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Savings Pot")
                .font(.system(size: 18, weight: .semibold))
            
            // Preview
            VStack(spacing: 6) {
                Image(systemName: selectedIcon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: selectedColor))
                    .frame(width: 52, height: 52)
                    .background(Color(hex: selectedColor).opacity(0.12))
                    .clipShape(Circle())
                
                Text(name.isEmpty ? "Pot Name" : name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(name.isEmpty ? Color(uiColor: .tertiaryLabel) : Color(uiColor: .label))
            }
            
            TextField("Name (e.g., Savings, Investment)", text: $name)
                .font(.system(size: 15))
                .padding(12)
                .background(Color(uiColor: .tertiarySystemFill))
                .cornerRadius(10)
            
            // Icon picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: { selectedIcon = icon }) {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundColor(selectedIcon == icon ? .white : Color(uiColor: .label))
                                .frame(width: 38, height: 38)
                                .background(selectedIcon == icon ? Color(hex: selectedColor) : Color(uiColor: .tertiarySystemFill))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            
            // Color picker
            HStack(spacing: 10) {
                ForEach(colors, id: \.self) { color in
                    Button(action: { selectedColor = color }) {
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                            )
                            .overlay(
                                Circle().stroke(Color(hex: color), lineWidth: selectedColor == color ? 1 : 0).padding(2)
                            )
                    }
                }
            }
            
            Spacer()
            
            Button(action: createPot) {
                Text("Create Pot")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(name.isEmpty ? Color(uiColor: .systemGray3) : Theme.Colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(name.isEmpty)
        }
        .padding(20)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
    }
    
    private func createPot() {
        let pot = Goal(
            title: name,
            icon: selectedIcon,
            color: selectedColor,
            goalType: .envelope
        )
        viewModel.addGoal(pot)
        Haptics.success()
        dismiss()
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                Spacer()
                
                Text(formatCurrency(total, currency: viewModel.appState.selectedCurrency))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(uiColor: .label))
                    .contentTransition(.numericText(value: total))
                    .animation(.snappy, value: total)
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
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(height: 8)
            }
            
            VStack(spacing: 8) {
                ForEach(items) { item in
                    HStack(spacing: 8) {
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
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Weekly Balance Chart
struct WeeklyBalanceChart: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    private var data: [(weekLabel: String, endDate: Date, balance: Double)] {
        viewModel.weeklyBalanceHistory(weeks: 8)
    }
    
    private var minBalance: Double {
        (data.map(\.balance).min() ?? 0) * 0.9
    }
    
    private var maxBalance: Double {
        let mx = data.map(\.balance).max() ?? 100
        return mx * 1.1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Balance Trend")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                Spacer()
                
                if let last = data.last {
                    Text(formatCurrency(last.balance, currency: viewModel.appState.selectedCurrency))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            if data.isEmpty || data.allSatisfy({ $0.balance == 0 }) {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.Colors.primary.opacity(0.3))
                    
                    Text("Not enough data yet")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                        LineMark(
                            x: .value("Week", point.weekLabel),
                            y: .value("Balance", point.balance)
                        )
                        .foregroundStyle(Theme.Colors.primary)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        
                        AreaMark(
                            x: .value("Week", point.weekLabel),
                            yStart: .value("Min", minBalance),
                            yEnd: .value("Balance", point.balance)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.Colors.primary.opacity(0.2), Theme.Colors.primary.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        if index == data.count - 1 {
                            PointMark(
                                x: .value("Week", point.weekLabel),
                                y: .value("Balance", point.balance)
                            )
                            .foregroundStyle(Theme.Colors.primary)
                            .symbolSize(40)
                        }
                    }
                }
                .chartYScale(domain: minBalance...maxBalance)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel()
                            .font(.system(size: 9))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisValueLabel()
                            .font(.system(size: 9))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        AxisGridLine()
                            .foregroundStyle(Color(uiColor: .separator).opacity(0.3))
                    }
                }
                .frame(height: 140)
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Calendar Section
struct HomeCalendarSection: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var selectedDate = Date()
    @State private var tappedDate: Date? = nil
    
    private var cal: Calendar { Calendar.current }
    
    private var monthDays: [Date] {
        guard let range = cal.range(of: .day, in: .month, for: selectedDate),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate)) else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: firstOfMonth) }
    }
    
    private var firstWeekday: Int {
        guard let first = monthDays.first else { return 0 }
        return (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
    }
    
    private func transactionsFor(_ date: Date) -> [Transaction] {
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        return viewModel.transactions.filter { $0.date >= start && $0.date < end }
    }
    
    private func recurringDueOn(_ date: Date) -> [RecurringTransaction] {
        viewModel.recurringTransactions.filter { r in
            r.isActive && cal.isDate(r.nextDueDate, inSameDayAs: date)
        }
    }
    
    private func goalsDueOn(_ date: Date) -> [Goal] {
        viewModel.goals.filter { g in
            !g.isCompleted && g.deadline != nil && cal.isDate(g.deadline!, inSameDayAs: date)
        }
    }
    
    private func eventsForDate(_ date: Date) -> (hasIncome: Bool, hasExpense: Bool, hasRecurring: Bool, hasGoal: Bool) {
        let txs = transactionsFor(date)
        let hasIncome = txs.contains { $0.type == .income }
        let hasExpense = txs.contains { $0.type == .expense }
        let hasRecurring = !recurringDueOn(date).isEmpty
        let hasGoal = !goalsDueOn(date).isEmpty
        return (hasIncome, hasExpense, hasRecurring, hasGoal)
    }
    
    private var monthLabel: String {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df.string(from: selectedDate)
    }
    
    private var selectedDayEvents: [(icon: String, label: String, color: Color)] {
        guard let date = tappedDate else { return [] }
        var events: [(icon: String, label: String, color: Color)] = []
        
        for tx in transactionsFor(date) {
            let cat = viewModel.categories.first { $0.id == tx.categoryId }
            let icon = cat?.icon ?? (tx.type == .income ? "arrow.down" : "arrow.up")
            let color = tx.type == .income ? Theme.Colors.income : Theme.Colors.expense
            events.append((icon: icon, label: "\(tx.title) — \(formatCurrency(tx.amount, currency: viewModel.appState.selectedCurrency))", color: color))
        }
        
        for r in recurringDueOn(date) {
            events.append((icon: "repeat", label: "\(r.title) due", color: Theme.Colors.recurring))
        }
        
        for g in goalsDueOn(date) {
            let label = g.isEnvelope ? "\(g.title) pot target" : "\(g.title) deadline"
            events.append((icon: g.icon, label: label, color: Theme.Colors.goals))
        }
        
        return events
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation { selectedDate = cal.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    
                    Text(monthLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Button(action: {
                        withAnimation { selectedDate = cal.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
            }
            
            // Legend
            HStack(spacing: 12) {
                CalendarLegendDot(color: Theme.Colors.income, label: "Income")
                CalendarLegendDot(color: Theme.Colors.expense, label: "Expense")
                CalendarLegendDot(color: Theme.Colors.recurring, label: "Recurring")
                CalendarLegendDot(color: Theme.Colors.goals, label: "Goal")
            }
            .padding(.bottom, 2)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                        .frame(height: 16)
                }
                
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Text("").frame(height: 40)
                }
                
                ForEach(monthDays, id: \.self) { date in
                    let isToday = cal.isDateInToday(date)
                    let isTapped = tappedDate != nil && cal.isDate(date, inSameDayAs: tappedDate!)
                    let events = eventsForDate(date)
                    
                    Button {
                        withAnimation(.snappy) {
                            if isTapped { tappedDate = nil } else { tappedDate = date }
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(cal.component(.day, from: date))")
                                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                                .foregroundColor(isToday ? .white : isTapped ? Theme.Colors.primary : Color(uiColor: .label))
                                .frame(width: 28, height: 28)
                                .background(isToday ? Theme.Colors.primary : isTapped ? Theme.Colors.primary.opacity(0.1) : Color.clear)
                                .clipShape(Circle())
                            
                            HStack(spacing: 2) {
                                if events.hasIncome { Circle().fill(Theme.Colors.income).frame(width: 4, height: 4) }
                                if events.hasExpense { Circle().fill(Theme.Colors.expense).frame(width: 4, height: 4) }
                                if events.hasRecurring { Circle().fill(Theme.Colors.recurring).frame(width: 4, height: 4) }
                                if events.hasGoal { Circle().fill(Theme.Colors.goals).frame(width: 4, height: 4) }
                            }
                            .frame(height: 4)
                        }
                        .frame(height: 40)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if let _ = tappedDate, !selectedDayEvents.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(selectedDayEvents.enumerated()), id: \.offset) { _, event in
                        HStack(spacing: 8) {
                            Image(systemName: event.icon)
                                .font(.system(size: 11))
                                .foregroundColor(event.color)
                                .frame(width: 22, height: 22)
                                .background(event.color.opacity(0.1))
                                .clipShape(Circle())
                            
                            Text(event.label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(uiColor: .label))
                                .lineLimit(1)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if let date = tappedDate {
                Text("Nothing on \(formatDayLabel(date))")
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 6)
                    .transition(.opacity)
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
    
    private func formatDayLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: date)
    }
}

private struct CalendarLegendDot: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
    }
}

// MARK: - Accounts Section
struct AccountsSection: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "My Accounts") {
                // Navigation handled by NavigationLink below
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
                        VStack(spacing: 8) {
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
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(14)
                    }
                }
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

struct AccountCard: View {
    let account: Account
    let balance: Double
    let currency: String
    
    var body: some View {
        VStack(spacing: 8) {
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
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Goals Summary (always visible)
struct GoalsSummarySection: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    private var activeGoals: [Goal] {
        viewModel.goals.filter { $0.goalType == .goal && !$0.isCompleted }
    }
    
    private var completedCount: Int {
        viewModel.goals.filter { $0.goalType == .goal && $0.isCompleted }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Goals")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                Spacer()
                
                NavigationLink(destination: MoreView(viewModel: viewModel)) {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            if activeGoals.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "target")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.goals.opacity(0.4))
                    
                    Text("No active goals")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Text("Set savings targets to track your progress")
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 10) {
                    ForEach(activeGoals.prefix(3)) { goal in
                        GoalItemRow(goal: goal, currency: viewModel.appState.selectedCurrency)
                    }
                }
                
                if completedCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.income)
                        Text("\(completedCount) completed")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

struct GoalItemRow: View {
    let goal: Goal
    let currency: String
    
    private var progress: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(1, goal.currentAmount / goal.targetAmount)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: goal.icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: goal.color))
                .frame(width: 34, height: 34)
                .background(Color(hex: goal.color).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(goal.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(uiColor: .label))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: goal.color))
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(uiColor: .tertiarySystemFill))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(Color(hex: goal.color))
                            .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 4)
                    }
                }
                .frame(height: 4)
                
                HStack {
                    Text(formatCurrency(goal.currentAmount, currency: currency))
                        .font(.system(size: 11))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Spacer()
                    
                    Text(formatCurrency(goal.targetAmount, currency: currency))
                        .font(.system(size: 11))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }
        }
    }
}

// MARK: - Recurring Summary (always visible)
struct RecurringSummarySection: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    private var activeRecurring: [RecurringTransaction] {
        viewModel.recurringTransactions.filter { $0.isActive }
    }
    
    private var monthlyTotal: Double {
        activeRecurring.reduce(0) { total, rt in
            let multiplier: Double
            switch rt.frequency {
            case .daily: multiplier = 30
            case .weekly: multiplier = 4.33
            case .biweekly: multiplier = 2.17
            case .monthly: multiplier = 1
            case .quarterly: multiplier = 0.33
            case .yearly: multiplier = 0.083
            }
            return total + (rt.type == .expense ? rt.amount * multiplier : 0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recurring")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
                
                Spacer()
                
                NavigationLink(destination: RecurringView(viewModel: viewModel)) {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            if activeRecurring.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.recurring.opacity(0.3))
                    
                    Text("No recurring transactions")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Text("Add subscriptions, rent, salary and more")
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.recurring)
                        .frame(width: 36, height: 36)
                        .background(Theme.Colors.recurring.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly estimate")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        
                        Text(formatCurrency(monthlyTotal, currency: viewModel.appState.selectedCurrency))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(uiColor: .label))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(activeRecurring.count) active")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        
                        if viewModel.overdueRecurring.count > 0 {
                            Text("\(viewModel.overdueRecurring.count) overdue")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(uiColor: .systemRed))
                        } else if viewModel.upcomingRecurring.count > 0 {
                            Text("\(viewModel.upcomingRecurring.count) upcoming")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
                
                VStack(spacing: 0) {
                    ForEach(Array(activeRecurring.prefix(3).enumerated()), id: \.element.id) { index, recurring in
                        RecurringItemRow(
                            recurring: recurring,
                            category: viewModel.getCategory(by: recurring.categoryId),
                            currency: viewModel.appState.selectedCurrency
                        )
                        
                        if index < min(activeRecurring.count, 3) - 1 {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                
                if activeRecurring.count > 3 {
                    NavigationLink(destination: RecurringView(viewModel: viewModel)) {
                        Text("View all \(activeRecurring.count) recurring")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

struct RecurringItemRow: View {
    let recurring: RecurringTransaction
    let category: Category?
    let currency: String
    
    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: recurring.nextDueDate).day ?? 0
    }
    
    private var dueLabel: String {
        if daysUntilDue < 0 { return "Overdue" }
        if daysUntilDue == 0 { return "Due today" }
        if daysUntilDue == 1 { return "Tomorrow" }
        return "In \(daysUntilDue) days"
    }
    
    private var dueColor: Color {
        if daysUntilDue < 0 { return Color(uiColor: .systemRed) }
        if daysUntilDue <= 2 { return Theme.Colors.recurring }
        return Color(uiColor: .secondaryLabel)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category?.icon ?? recurring.frequency.icon)
                .font(.system(size: 14))
                .foregroundColor(category?.colorValue ?? Theme.Colors.recurring)
                .frame(width: 34, height: 34)
                .background((category?.colorValue ?? Theme.Colors.recurring).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 1) {
                Text(recurring.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(uiColor: .label))
                    .lineLimit(1)
                
                Text("\(recurring.frequency.rawValue) \u{2022} \(dueLabel)")
                    .font(.system(size: 11))
                    .foregroundColor(dueColor)
            }
            
            Spacer()
            
            Text(recurring.type == .income ? "+\(formatCurrency(recurring.amount, currency: currency))" : "-\(formatCurrency(recurring.amount, currency: currency))")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(recurring.type == .income ? Theme.Colors.income : Theme.Colors.expense)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Daily Tips Section
struct DailyTipsSection: View {
    private static let allTips: [(icon: String, title: String, tip: String)] = [
        (icon: "lightbulb.max.fill", title: "50/30/20 Rule", tip: "Try allocating 50% for needs, 30% for wants, and 20% for savings."),
        (icon: "chart.pie.fill", title: "Track Everything", tip: "Small expenses add up! Record every purchase to see where your money goes."),
        (icon: "arrow.up.right.circle.fill", title: "Pay Yourself First", tip: "Set aside savings before spending on anything else."),
        (icon: "calendar", title: "Weekly Reviews", tip: "Check your spending every week to stay on track with your goals."),
        (icon: "creditcard.fill", title: "Avoid Impulse Buys", tip: "Wait 24 hours before making non-essential purchases over $20."),
        (icon: "banknote.fill", title: "Emergency Fund", tip: "Try to save 3-6 months of expenses for unexpected costs."),
        (icon: "arrow.triangle.2.circlepath", title: "Automate Savings", tip: "Set up automatic transfers to your savings account each payday."),
        (icon: "cup.and.saucer.fill", title: "Latte Factor", tip: "Skipping a $5 daily coffee could save you over $1,800 a year."),
        (icon: "cart.fill", title: "Shopping Lists", tip: "Always make a list before shopping — it helps avoid unplanned spending."),
        (icon: "gift.fill", title: "No-Spend Days", tip: "Challenge yourself to one no-spend day per week to boost savings."),
        (icon: "target", title: "Set Short Goals", tip: "Break big savings goals into smaller weekly milestones for motivation."),
        (icon: "chart.line.uptrend.xyaxis", title: "Invest Early", tip: "Even small amounts invested consistently grow significantly over time."),
        (icon: "envelope.fill", title: "Envelope Method", tip: "Use savings pots to allocate money for specific purposes and avoid overspending."),
        (icon: "percent", title: "1% More", tip: "Increasing your savings rate by just 1% each month adds up fast."),
        (icon: "fork.knife", title: "Meal Prep", tip: "Cooking at home instead of eating out can save hundreds every month."),
    ]
    
    private var todaysTips: [(icon: String, title: String, tip: String)] {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        var rng = SeededRandomNumberGenerator(seed: UInt64(dayOfYear))
        let shuffled = Self.allTips.shuffled(using: &rng)
        return Array(shuffled.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Tips")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(uiColor: .label))
            
            ForEach(Array(todaysTips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: tip.icon)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 36, height: 36)
                        .background(Theme.Colors.primary.opacity(0.08))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(tip.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .label))
                        
                        Text(tip.tip)
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(3)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding(18)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - Profile Avatar
struct ProfileAvatarView: View {
    let imageData: Data?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(width: size, height: size)
            
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
    }
}

// MARK: - Profile Detail (redirects to full profile in More)
struct ProfileDetailView: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    var body: some View {
        NewProfileView(viewModel: viewModel)
    }
}

// MARK: - Helpers
func formatCurrency(_ amount: Double, currency: String = "USD") -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
}

func formatSignedCurrency(_ amount: Double, currency: String = "USD") -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    let formatted = formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    return amount >= 0 ? "+\(formatted)" : "-\(formatted)"
}

func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

#Preview {
    MainTabView(viewModel: BalanceViewModel())
}

