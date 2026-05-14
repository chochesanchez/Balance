import Foundation

@MainActor
struct AssistantService {
    let viewModel: BalancedViewModel

    enum Intent: String, CaseIterable {
        case spentThisMonth
        case topCategory
        case canAfford
        case weeklySavingForGoal
        case goalNeedingAttention
        case changeVsLastMonth
        case upcomingBills
        case summary
        case unknown
    }

    struct Response {
        let title: String
        let body: String
        let followUps: [String]
    }

    func answer(_ question: String) -> Response {
        let intent = classify(question)
        switch intent {
        case .spentThisMonth: return spentThisMonth()
        case .topCategory: return topCategory()
        case .canAfford: return canAfford(question: question)
        case .weeklySavingForGoal: return weeklySavingForGoal()
        case .goalNeedingAttention: return goalNeedingAttention()
        case .changeVsLastMonth: return changeVsLastMonth()
        case .upcomingBills: return upcomingBills()
        case .summary: return monthSummary()
        case .unknown: return fallback()
        }
    }

    static let starterPrompts: [String] = [
        "How much did I spend this month?",
        "What category am I spending most on?",
        "Can I afford $80 right now?",
        "How much should I save weekly for my goal?",
        "Which goal needs attention?",
        "What changed from last month?",
        "What bills are coming up?",
        "Give me a monthly summary"
    ]

    private func classify(_ question: String) -> Intent {
        let q = question.lowercased()
        if q.contains("spend") && (q.contains("month") || q.contains("this month")) { return .spentThisMonth }
        if q.contains("category") || q.contains("most on") || q.contains("biggest") { return .topCategory }
        if q.contains("afford") || q.contains("can i buy") || q.contains("can i spend") { return .canAfford }
        if (q.contains("save") || q.contains("saving")) && (q.contains("week") || q.contains("goal")) { return .weeklySavingForGoal }
        if q.contains("goal") && (q.contains("attention") || q.contains("behind") || q.contains("status")) { return .goalNeedingAttention }
        if q.contains("change") && q.contains("last") { return .changeVsLastMonth }
        if q.contains("bill") || q.contains("recurring") || q.contains("upcoming") { return .upcomingBills }
        if q.contains("summary") || q.contains("recap") || q.contains("overview") { return .summary }
        return .unknown
    }

    private func spentThisMonth() -> Response {
        let exp = viewModel.monthlyExpenses
        let inc = viewModel.monthlyIncome
        let cur = viewModel.appState.selectedCurrency
        let savedNet = inc - exp
        let body: String
        if exp == 0 {
            body = "You haven't recorded any spending this month yet."
        } else {
            body = "You've spent \(format(exp, currency: cur)) so far this month, against \(format(inc, currency: cur)) of income. That's a net of \(format(savedNet, currency: cur))."
        }
        return Response(title: "This month so far", body: body,
                        followUps: ["What category am I spending most on?", "What's my month-end forecast?"])
    }

    private func topCategory() -> Response {
        guard let top = viewModel.topCategoryStats.first else {
            return Response(title: "No category data yet",
                            body: "Once you record categorised expenses, I'll point out where most of your money is going.",
                            followUps: ["How much did I spend this month?"])
        }
        let cur = viewModel.appState.selectedCurrency
        var lines = ["\(top.category.name) — \(format(top.total, currency: cur)) (\(Int(top.percentOfTotal * 100))% of spend)"]
        if let d = top.deltaFromPrevious {
            let arrow = d >= 0 ? "↑" : "↓"
            lines.append("\(arrow) \(Int(abs(d) * 100))% vs the previous period.")
        }
        return Response(title: "Biggest category", body: lines.joined(separator: "\n"),
                        followUps: ["Can I afford $50?", "What changed from last month?"])
    }

    private func canAfford(question: String) -> Response {
        let amount = parseFirstNumber(in: question) ?? 50
        let cur = viewModel.appState.selectedCurrency
        let totalBalance = viewModel.totalBalance
        let limit = viewModel.appState.weeklySpendingLimit
        let weekSpend: Double
        if let interval = TimeRange.weekly.dateInterval() {
            weekSpend = viewModel.transactions
                .filter { $0.type == .expense && $0.date >= interval.start && $0.date < interval.end }
                .reduce(0) { $0 + $1.amount }
        } else { weekSpend = 0 }

        if totalBalance < amount {
            return Response(title: "Probably not right now",
                            body: "Your available balance across accounts is \(format(totalBalance, currency: cur)). Buying \(format(amount, currency: cur)) would push you below zero.",
                            followUps: ["Which goal needs attention?", "How can I save more this week?"])
        }
        if limit > 0 {
            let projected = weekSpend + amount
            if projected > limit {
                let over = projected - limit
                return Response(title: "Yes, but it'll break your limit",
                                body: "You can afford \(format(amount, currency: cur)), but it would put your weekly spend at \(format(projected, currency: cur)) — \(format(over, currency: cur)) over your \(format(limit, currency: cur)) limit.",
                                followUps: ["What bills are coming up?", "What's my month-end forecast?"])
            }
            return Response(title: "Yes — comfortably",
                            body: "You can afford \(format(amount, currency: cur)). After this purchase you'd still be under your weekly limit by \(format(limit - projected, currency: cur)).",
                            followUps: ["What category am I spending most on?"])
        }
        return Response(title: "Yes",
                        body: "Across all accounts you have \(format(totalBalance, currency: cur)), so \(format(amount, currency: cur)) is within reach. Consider setting a weekly limit to keep tabs.",
                        followUps: ["Give me a monthly summary"])
    }

    private func weeklySavingForGoal() -> Response {
        let cur = viewModel.appState.selectedCurrency
        let goals = viewModel.activeGoals.filter { $0.targetAmount > 0 && $0.linkedAccountId == nil }
        guard let goal = goals.sorted(by: { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }).first else {
            return Response(title: "No goal to plan against",
                            body: "Create a goal with a target amount and (optionally) a deadline, and I'll work out a weekly savings plan.",
                            followUps: ["Give me a monthly summary"])
        }
        let remaining = max(0, goal.targetAmount - viewModel.effectiveCurrentAmount(for: goal))
        let weeks: Int
        if let deadline = goal.deadline {
            let secs = max(deadline.timeIntervalSinceNow, 86400)
            weeks = max(1, Int(secs / (86400 * 7)))
        } else {
            weeks = 12
        }
        let perWeek = remaining / Double(weeks)
        return Response(title: "Plan for \(goal.title)",
                        body: "You need \(format(remaining, currency: cur)) more. Saving about \(format(perWeek, currency: cur)) per week would get you there\(goal.deadline == nil ? " in ~3 months" : " by your deadline").",
                        followUps: ["Which goal needs attention?", "Can I afford $20?"])
    }

    private func goalNeedingAttention() -> Response {
        let cur = viewModel.appState.selectedCurrency
        let candidates = viewModel.activeGoals.filter { $0.targetAmount > 0 }
        let behind = candidates.first { viewModel.status(for: $0) == .behind }
        if let g = behind {
            let remaining = max(0, g.targetAmount - viewModel.effectiveCurrentAmount(for: g))
            return Response(title: "Behind: \(g.title)",
                            body: "This goal is falling behind schedule. \(format(remaining, currency: cur)) still to go. A small extra contribution this week would get you back on track.",
                            followUps: ["How much should I save weekly for my goal?"])
        }
        let oldest = candidates.sorted { $0.createdAt < $1.createdAt }.first
        if let g = oldest {
            return Response(title: "Keep going: \(g.title)",
                            body: "All your goals are on pace. Your longest-running goal is \(g.title) — \(Int(g.progress))% complete.",
                            followUps: ["Give me a monthly summary"])
        }
        return Response(title: "No goals yet",
                        body: "Once you create a goal I'll watch its pace and flag it if it slips.",
                        followUps: ["How much did I spend this month?"])
    }

    private func changeVsLastMonth() -> Response {
        let cur = viewModel.appState.selectedCurrency
        let inc = viewModel.incomeDelta
        let exp = viewModel.expenseDelta
        let parts = [
            "Income: \(inc >= 0 ? "+" : "")\(format(inc, currency: cur))",
            "Expenses: \(exp >= 0 ? "+" : "")\(format(exp, currency: cur))"
        ]
        return Response(title: "Vs. previous \(viewModel.appState.preferredTimeRange.shortTitle.lowercased())",
                        body: parts.joined(separator: "\n"),
                        followUps: ["What category am I spending most on?"])
    }

    private func upcomingBills() -> Response {
        let cur = viewModel.appState.selectedCurrency
        let upcoming = viewModel.upcomingRecurring
        if upcoming.isEmpty {
            return Response(title: "No bills in the next 7 days",
                            body: "Nothing recurring is due this week.",
                            followUps: ["Give me a monthly summary"])
        }
        let total = upcoming.reduce(0) { $0 + $1.amount }
        let lines = upcoming.prefix(5).map { r in
            "• \(r.title) — \(format(r.amount, currency: cur)) in \(r.daysUntilDue)d"
        }.joined(separator: "\n")
        return Response(title: "\(upcoming.count) bill\(upcoming.count == 1 ? "" : "s") coming up",
                        body: "\(lines)\n\nTotal expected: \(format(total, currency: cur)).",
                        followUps: ["Can I afford to pay all of these?"])
    }

    private func monthSummary() -> Response {
        let cur = viewModel.appState.selectedCurrency
        let inc = viewModel.monthlyIncome
        let exp = viewModel.monthlyExpenses
        let net = inc - exp
        let rate = inc > 0 ? Int((net / inc) * 100) : 0
        let topCat = viewModel.topCategoryStats.first?.category.name ?? "—"
        let body = """
        Income: \(format(inc, currency: cur))
        Expenses: \(format(exp, currency: cur))
        Net: \(format(net, currency: cur)) (\(rate)% savings rate)
        Top category: \(topCat)
        """
        return Response(title: "This month so far", body: body,
                        followUps: ["What changed from last month?", "Which goal needs attention?"])
    }

    private func fallback() -> Response {
        Response(title: "I can help with…",
                 body: "Try one of the suggestions below. I work entirely from your local Balance data, so I won't know about things you haven't recorded.",
                 followUps: Array(Self.starterPrompts.prefix(4)))
    }

    private func format(_ amount: Double, currency: String) -> String {
        formatCurrency(amount, currency: currency)
    }

    private func parseFirstNumber(in text: String) -> Double? {
        var cleaned = text.replacingOccurrences(of: ",", with: "")
        for symbol in ["$", "€", "£", "¥", "₹"] { cleaned = cleaned.replacingOccurrences(of: symbol, with: " ") }
        let parts = cleaned.split { !($0.isNumber || $0 == ".") }
        for part in parts {
            if let v = Double(part), v > 0 { return v }
        }
        return nil
    }
}
