import SwiftUI

// MARK: - Goals Summary Section
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
                    .font(Theme.Typography.headline)
                    .foregroundColor(Color(uiColor: .label))

                Spacer()

                NavigationLink(destination: GoalsListView(viewModel: viewModel)) {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
                .accessibilityLabel("See all goals")
            }

            if activeGoals.isEmpty {
                VStack(spacing: Theme.Spacing.sm) {
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
                .accessibilityLabel("No active goals. Set savings targets to track your progress.")
            } else {
                VStack(spacing: Theme.Spacing.sm) {
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
                    .accessibilityLabel("\(completedCount) goals completed")
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.CornerRadius.large)
    }
}

// MARK: - Goal Item Row
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.title), \(Int(progress * 100))% complete, \(formatCurrency(goal.currentAmount, currency: currency)) of \(formatCurrency(goal.targetAmount, currency: currency))")
    }
}

// MARK: - Recurring Summary Section
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
                    .font(Theme.Typography.headline)
                    .foregroundColor(Color(uiColor: .label))

                Spacer()

                NavigationLink(destination: RecurringView(viewModel: viewModel)) {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
                .accessibilityLabel("See all recurring transactions")
            }

            if activeRecurring.isEmpty {
                VStack(spacing: Theme.Spacing.sm) {
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
                .accessibilityLabel("No recurring transactions. Add subscriptions, rent, salary and more.")
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
                            .accessibilityLabel("Monthly estimate")
                            .accessibilityValue(formatCurrency(monthlyTotal, currency: viewModel.appState.selectedCurrency))
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
                                .accessibilityLabel("\(viewModel.overdueRecurring.count) overdue recurring")
                        } else if viewModel.upcomingRecurring.count > 0 {
                            Text("\(viewModel.upcomingRecurring.count) upcoming")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.Colors.primary)
                                .accessibilityLabel("\(viewModel.upcomingRecurring.count) upcoming recurring")
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
                    .accessibilityLabel("View all \(activeRecurring.count) recurring transactions")
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.CornerRadius.large)
    }
}

// MARK: - Recurring Item Row
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recurring.title), \(recurring.frequency.rawValue), \(dueLabel), \(formatCurrency(recurring.amount, currency: currency))")
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
                .font(Theme.Typography.headline)
                .foregroundColor(Color(uiColor: .label))

            ForEach(Array(todaysTips.enumerated()), id: \.offset) { _, tip in
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
                .cornerRadius(Theme.CornerRadius.medium)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(tip.title): \(tip.tip)")
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.CornerRadius.large)
    }
}

// MARK: - Seeded RNG (deterministic daily tip rotation)
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
