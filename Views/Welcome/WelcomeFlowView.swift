import SwiftUI

struct WelcomeFlowView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .welcome
    @State private var accountName: String = "Cash"
    @State private var accountType: AccountType = .cash
    @State private var balanceText: String = ""
    @State private var didSkipFirstAccount = false

    enum Step: Int {
        case welcome
        case createAccount
        case starterCategories
        case sampleData
        case ready
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(spacing: 22) {
                        switch step {
                        case .welcome: welcomeStep
                        case .createAccount: createAccountStep
                        case .starterCategories: starterCategoriesStep
                        case .sampleData: sampleDataStep
                        case .ready: readyStep
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
                bottomBar
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true)
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { idx in
                Capsule()
                    .fill(idx <= step.rawValue ? Theme.Colors.primary : Color(uiColor: .tertiarySystemFill))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .accessibilityElement()
        .accessibilityLabel("Step \(step.rawValue + 1) of 5")
    }

    private var welcomeStep: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.7)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .accessibilityHidden(true)
            }
            Text("Welcome to Balance")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            Text("A simple, private way to track your money as a student. Let's get your dashboard ready in a minute.")
                .font(.system(size: 15))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            VStack(alignment: .leading, spacing: 10) {
                bullet("Your money stays on your device and your iCloud.")
                bullet("No accounts, no ads, no trackers.")
                bullet("AI insights and unlimited goals with Balance Plus — optional.")
            }
            .padding(.top, 8)
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.Colors.income)
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .label))
        }
        .accessibilityElement(children: .combine)
    }

    private var createAccountStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Add your first account",
                      subtitle: "Pick something you actually use. You can change everything later.")

            VStack(spacing: 0) {
                row("Name") {
                    TextField("Cash", text: $accountName)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Account name")
                }
                Divider().padding(.leading, 16)
                HStack {
                    Text("Type").font(.system(size: 15))
                    Spacer()
                    Picker("Type", selection: $accountType) {
                        ForEach(AccountType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                    .tint(Color(uiColor: .secondaryLabel))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                Divider().padding(.leading, 16)
                row("Starting balance") {
                    TextField("0.00", text: $balanceText)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Starting balance")
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(14)

            Text("Starting balance won't be counted as income. It's just the amount you have today.")
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: .secondaryLabel))

            Button {
                didSkipFirstAccount = true
                advance()
            } label: {
                Text("I'll do this later")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }

    private var starterCategoriesStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Starter categories",
                      subtitle: "We added 15 categories tailored for students. You can edit, add, or remove them anytime.")
            VStack(alignment: .leading, spacing: 10) {
                Text("Spending").font(.system(size: 12, weight: .semibold)).foregroundColor(Color(uiColor: .secondaryLabel))
                grid(["Food","Groceries","Coffee","Transportation","Rent","School","Subscriptions","Entertainment","Health","Shopping"], color: Theme.Colors.expense)
                Text("Income").font(.system(size: 12, weight: .semibold)).foregroundColor(Color(uiColor: .secondaryLabel)).padding(.top, 6)
                grid(["Allowance","Scholarship","Part-time Job","Gift","Other Income"], color: Theme.Colors.income)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
    }

    private func grid(_ items: [String], color: Color) -> some View {
        let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items, id: \.self) { name in
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.12))
                    .foregroundColor(color)
                    .clipShape(Capsule())
            }
        }
    }

    private var sampleDataStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Try with sample data?",
                      subtitle: "Optional. Adds a few sample transactions so the dashboard isn't empty. You can remove them with one tap later.")
            VStack(spacing: 10) {
                Button {
                    if viewModel.demoTransactionIds.isEmpty {
                        viewModel.installSampleDemoData()
                    }
                    advance()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .accessibilityHidden(true)
                        Text("Add sample data")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Add sample data")

                Button {
                    advance()
                } label: {
                    Text("Skip sample data")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.primary.opacity(0.08))
                        .cornerRadius(12)
                }
            }
        }
    }

    private var readyStep: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.income.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Theme.Colors.income)
                    .accessibilityHidden(true)
            }
            Text("You're ready.")
                .font(.system(size: 26, weight: .bold))
            Text("Tap Continue to open your dashboard. You can revisit this in Settings → Data & Backup any time.")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 22, weight: .bold))
            Text(subtitle).font(.system(size: 14)).foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }

    @ViewBuilder
    private func row<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label).font(.system(size: 15))
            Spacer()
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var bottomBar: some View {
        VStack(spacing: 6) {
            Button(action: advance) {
                Text(primaryTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canAdvance ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.4))
                    .cornerRadius(14)
            }
            .disabled(!canAdvance)
            .accessibilityLabel(primaryTitle)

            if step != .welcome && step != .ready {
                Button("Back") {
                    if let prev = Step(rawValue: step.rawValue - 1) {
                        withAnimation(.snappy) { step = prev }
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(uiColor: .systemBackground).opacity(0.95))
    }

    private var primaryTitle: String {
        switch step {
        case .welcome: return "Get started"
        case .createAccount: return didSkipFirstAccount ? "Continue" : "Create account"
        case .starterCategories: return "Add starter categories"
        case .sampleData: return "Continue"
        case .ready: return "Continue to dashboard"
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .createAccount:
            if didSkipFirstAccount { return true }
            return !accountName.trimmingCharacters(in: .whitespaces).isEmpty
        default:
            return true
        }
    }

    private func advance() {
        switch step {
        case .welcome:
            withAnimation(.snappy) { step = .createAccount }
        case .createAccount:
            if !didSkipFirstAccount {
                let trimmed = accountName.trimmingCharacters(in: .whitespaces)
                let initial = Double(balanceText.replacingOccurrences(of: ",", with: ".")) ?? 0
                let typeColor = accountType.defaultColor
                let typeIcon = accountType.defaultIcon
                if viewModel.accounts.allSatisfy({ $0.name != trimmed || $0.type != accountType }) {
                    let newAccount = Account(name: trimmed, type: accountType, icon: typeIcon, color: typeColor,
                                             initialBalance: initial, isDefault: viewModel.accounts.isEmpty)
                    viewModel.addAccount(newAccount)
                }
            }
            withAnimation(.snappy) { step = .starterCategories }
        case .starterCategories:
            viewModel.installStarterCategoriesIfMissing()
            withAnimation(.snappy) { step = .sampleData }
        case .sampleData:
            withAnimation(.snappy) { step = .ready }
        case .ready:
            Haptics.success()
            dismiss()
        }
    }
}
