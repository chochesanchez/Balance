import SwiftUI
import Charts

// MARK: - Weekly Balance Chart
struct WeeklyBalanceChart: View {
    @ObservedObject var viewModel: BalanceViewModel

    /// Uses the cached weeklyHistory from ViewModel (updated after each transaction).
    private var data: [(weekLabel: String, endDate: Date, balance: Double)] {
        viewModel.weeklyHistory
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
                    .font(Theme.Typography.headline)
                    .foregroundColor(Color(uiColor: .label))

                Spacer()

                if let last = data.last {
                    Text(formatCurrency(last.balance, currency: viewModel.appState.selectedCurrency))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Colors.primary)
                        .accessibilityLabel("Current balance")
                        .accessibilityValue(formatCurrency(last.balance, currency: viewModel.appState.selectedCurrency))
                }
            }

            if data.isEmpty || data.allSatisfy({ $0.balance == 0 }) {
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.Colors.primary.opacity(0.3))

                    Text("Not enough data yet")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .accessibilityLabel("Balance trend chart. Not enough data yet.")
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
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(.system(size: 9))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                        AxisValueLabel()
                            .font(.system(size: 9))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        AxisGridLine()
                            .foregroundStyle(Color(uiColor: .separator).opacity(0.3))
                    }
                }
                .frame(height: 140)
                .accessibilityLabel("8-week balance trend chart")
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.CornerRadius.large)
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
                    .font(Theme.Typography.headline)
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
                    .accessibilityLabel("Previous month")

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
                    .accessibilityLabel("Next month")
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
            .accessibilityHidden(true)

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
                    .accessibilityLabel(accessibilityLabelFor(date: date, events: events, isToday: isToday))
                }
            }

            if let _ = tappedDate, !selectedDayEvents.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(selectedDayEvents.enumerated()), id: \.offset) { _, event in
                        HStack(spacing: Theme.Spacing.xs) {
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
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.CornerRadius.large)
    }

    private func accessibilityLabelFor(date: Date, events: (hasIncome: Bool, hasExpense: Bool, hasRecurring: Bool, hasGoal: Bool), isToday: Bool) -> String {
        var parts: [String] = []
        let day = cal.component(.day, from: date)
        parts.append(isToday ? "Today, \(day)" : "\(day)")
        if events.hasIncome { parts.append("income") }
        if events.hasExpense { parts.append("expense") }
        if events.hasRecurring { parts.append("recurring bill") }
        if events.hasGoal { parts.append("goal deadline") }
        return parts.joined(separator: ", ")
    }

    private func formatDayLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: date)
    }
}

// MARK: - Calendar Legend Dot
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
