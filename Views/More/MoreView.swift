import SwiftUI
import PhotosUI
import Charts
import AppIntents

// MARK: - More View
struct MoreView: View {
    @ObservedObject var viewModel: BalancedViewModel
    
    var body: some View {
        List {
            // Profile
            Section {
                NavigationLink(destination: NewProfileView(viewModel: viewModel)) {
                    HStack(spacing: 14) {
                        ProfileAvatarView(imageData: viewModel.userProfile.profileImageData, size: 56)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.userProfile.name.isEmpty ? "Set up your profile" : viewModel.userProfile.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(uiColor: .label))
                            
                            Text(profileSubtitle)
                                .font(.system(size: 14))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            
            // Features
            Section("Features") {
                NavigationLink(destination: AnalyticsView(viewModel: viewModel)) {
                    MoreRowView(icon: "chart.bar.fill", title: "Analytics", color: Color(hex: "AF52DE"))
                }
                
                NavigationLink(destination: FinancialHealthView(viewModel: viewModel)) {
                    MoreRowView(icon: "heart.fill", title: "Financial Health", color: Color(uiColor: .systemPink))
                }
                
                NavigationLink(destination: GoalsListView(viewModel: viewModel)) {
                    MoreRowView(icon: "target", title: "Goals", color: Theme.Colors.goals)
                }

                NavigationLink(destination: SavingsPotsListView(viewModel: viewModel)) {
                    MoreRowView(icon: "tray.2.fill", title: "Savings Pots", color: Color(hex: "30D158"))
                }

                NavigationLink(destination: RecurringView(viewModel: viewModel)) {
                    RecurringBadgeRow(viewModel: viewModel)
                }

                NavigationLink(destination: DebtsListView(viewModel: viewModel)) {
                    MoreRowView(icon: "creditcard.fill", title: "Debts", color: Color(hex: "FF3B30"))
                }

                NavigationLink(destination: TipsView()) {
                    MoreRowView(icon: "lightbulb.max.fill", title: "Tips & Guides", color: Theme.Colors.primary)
                }
            }
            
            // Settings
            Section("Settings") {
                NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                    MoreRowView(icon: "gearshape.fill", title: "Settings", color: Color(uiColor: .systemGray))
                }
            }
            
            // iCloud Sync
            Section("iCloud") {
                iCloudSyncRow
            }

            // Features — Back Tap
            Section("Quick Access") {
                NavigationLink(destination: BackTapSetupView()) {
                    MoreRowView(icon: "hand.tap.fill", title: "Back Tap Quick Record", color: Theme.Colors.primary)
                }
                ShortcutsLink()
                    .shortcutsLinkStyle(.automaticOutline)
            }

            // About
            Section("About") {
                NavigationLink(destination: HelpView()) {
                    MoreRowView(icon: "questionmark.circle.fill", title: "Help & Support", color: Theme.Colors.income)
                }
                
                NavigationLink(destination: AboutBalancedView()) {
                    MoreRowView(icon: "info.circle.fill", title: "About Balanced", color: Theme.Colors.primary)
                }
            }
            
            #if DEBUG
            Section("Developer") {
                Button(action: { viewModel.resetOnboarding() }) {
                    MoreRowView(icon: "arrow.counterclockwise", title: "Reset Onboarding", color: Color(hex: "AF52DE"))
                }
                
                Button(action: { viewModel.resetAllData() }) {
                    MoreRowView(icon: "trash.fill", title: "Reset All Data", color: Theme.Colors.expense)
                }
            }
            #endif
        }
        .listStyle(.insetGrouped)
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var iCloudSyncRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "007AFF"))
                    .frame(width: 32, height: 32)
                Image(systemName: "icloud.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text("iCloud Sync")
                .font(.system(size: 17))
                .foregroundColor(Color(uiColor: .label))
            Spacer()
            if viewModel.iCloudSyncEnabled {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("On")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.income)
                    if let date = viewModel.lastSyncDate {
                        Text(formatTime(date))
                            .font(.system(size: 11))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            } else {
                Text("Sign in to iCloud")
                    .font(.system(size: 13))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.iCloudSyncEnabled
            ? "iCloud Sync is on\(viewModel.lastSyncDate.map { ", last synced \(formatTime($0))" } ?? "")"
            : "iCloud Sync is off. Sign in to iCloud in Settings to enable.")
    }

    private var profileSubtitle: String {
        if !viewModel.userProfile.username.isEmpty {
            return "@\(viewModel.userProfile.username)"
        } else if !viewModel.userProfile.email.isEmpty {
            return viewModel.userProfile.email
        }
        return "Tap to add details"
    }
}

// MARK: - Recurring Badge Row
struct RecurringBadgeRow: View {
    @ObservedObject var viewModel: BalancedViewModel
    
    private var badgeCount: Int {
        viewModel.overdueRecurring.count + viewModel.upcomingRecurring.filter { $0.isDueToday }.count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.Colors.recurring)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "repeat.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text("Recurring")
                .font(.system(size: 17))
                .foregroundColor(Color(uiColor: .label))
            
            Spacer()
            
            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.Colors.expense)
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - More Row View
struct MoreRowView: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(Color(uiColor: .label))
        }
    }
}

// MARK: - Profile View
struct NewProfileView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @State private var isEditing = false
    @State private var editingProfile: UserProfile
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    init(viewModel: BalancedViewModel) {
        self.viewModel = viewModel
        self._editingProfile = State(initialValue: viewModel.userProfile)
    }
    
    var body: some View {
        List {
            // Header
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Button(action: { showingImagePicker = true }) {
                            ZStack(alignment: .bottomTrailing) {
                                ProfileAvatarView(imageData: viewModel.userProfile.profileImageData, size: 100)
                                
                                Circle()
                                    .fill(Theme.Colors.primary)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 2, y: 2)
                            }
                        }
                        
                        VStack(spacing: 3) {
                            if isEditing {
                                TextField("Your Name", text: $editingProfile.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .multilineTextAlignment(.center)
                            } else {
                                Text(viewModel.userProfile.name.isEmpty ? "Set up profile" : viewModel.userProfile.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(uiColor: .label))
                            }
                            
                            if !viewModel.userProfile.username.isEmpty && !isEditing {
                                Text("@\(viewModel.userProfile.username)")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(uiColor: .secondaryLabel))
                            }
                        }
                        
                        HStack(spacing: 28) {
                            ProfileStat(value: "\(viewModel.transactions.count)", label: "Records")
                            ProfileStat(value: "\(viewModel.goals.count)", label: "Goals")
                            ProfileStat(value: "\(viewModel.accounts.count)", label: "Accounts")
                        }
                        .padding(.top, 4)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
            // Personal Information
            Section("Personal Information") {
                if isEditing {
                    HStack {
                        Image(systemName: "at")
                            .foregroundColor(Color(hex: "5856D6"))
                            .frame(width: 24)
                        TextField("Username", text: $editingProfile.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Theme.Colors.recurring)
                            .frame(width: 24)
                        TextField("Email", text: $editingProfile.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(Theme.Colors.income)
                            .frame(width: 24)
                        TextField("Phone", text: $editingProfile.phone)
                            .keyboardType(.phonePad)
                    }
                } else {
                    ProfileRow(icon: "person.fill", iconColor: Theme.Colors.primary, title: "Name", value: viewModel.userProfile.name.isEmpty ? "Not set" : viewModel.userProfile.name)
                    ProfileRow(icon: "at", iconColor: Color(hex: "5856D6"), title: "Username", value: viewModel.userProfile.username.isEmpty ? "Not set" : "@\(viewModel.userProfile.username)")
                    ProfileRow(icon: "envelope.fill", iconColor: Theme.Colors.recurring, title: "Email", value: viewModel.userProfile.email.isEmpty ? "Not set" : viewModel.userProfile.email)
                    ProfileRow(icon: "phone.fill", iconColor: Theme.Colors.income, title: "Phone", value: viewModel.userProfile.phone.isEmpty ? "Not set" : viewModel.userProfile.phone)
                }
            }
            
            // Financial Goal
            if let goal = viewModel.userProfile.primaryGoal {
                Section("Financial Goal") {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.goals.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: goal.icon)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.goals)
                        }
                        Text(goal.rawValue)
                            .font(.system(size: 15))
                    }
                }
            }
            
            // Your Journey
            Section("Your Journey") {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 24)
                    Text("Member since")
                    Spacer()
                    Text(memberSince)
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Theme.Colors.income)
                        .frame(width: 24)
                    Text("Total tracked")
                    Spacer()
                    Text(formatCurrency(totalTracked, currency: viewModel.appState.selectedCurrency))
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                
                HStack {
                    Image(systemName: "percent")
                        .foregroundColor(viewModel.savingsRate >= 20 ? Theme.Colors.income : Theme.Colors.recurring)
                        .frame(width: 24)
                    Text("Savings rate")
                    Spacer()
                    Text(String(format: "%.0f%%", max(0, viewModel.savingsRate)))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.savingsRate >= 20 ? Theme.Colors.income : Color(uiColor: .secondaryLabel))
                }
            }
            
            // Preferences
            Section("Preferences") {
                NavigationLink(destination: CurrencySettingsView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Theme.Colors.income)
                            .frame(width: 24)
                        Text("Currency")
                        Spacer()
                        Text(viewModel.appState.selectedCurrency)
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        viewModel.updateUserProfile(editingProfile)
                        Haptics.success()
                    } else {
                        editingProfile = viewModel.userProfile
                    }
                    withAnimation(.snappy) { isEditing.toggle() }
                }
                .fontWeight(isEditing ? .semibold : .regular)
            }
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage, let data = image.jpegData(compressionQuality: 0.8) {
                viewModel.updateProfileImage(data)
                selectedImage = nil
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ProfileImagePicker(image: $selectedImage)
        }
    }
    
    private var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if let firstTransaction = viewModel.transactions.sorted(by: { $0.date < $1.date }).first {
            return formatter.string(from: firstTransaction.date)
        }
        return formatter.string(from: Date())
    }
    
    private var totalTracked: Double {
        viewModel.transactions.reduce(0) { $0 + $1.amount }
    }
}

struct ProfileStat: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color(uiColor: .label))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 15))
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }
}

struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Spacer()
            Text(value)
                .foregroundColor(Color(uiColor: .label))
        }
    }
}

// MARK: - Profile Image Picker
struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ProfileImagePicker
        init(_ parent: ProfileImagePicker) { self.parent = parent }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { [weak self] reading, _ in
                let loadedImage = reading as? UIImage
                DispatchQueue.main.async { self?.parent.image = loadedImage }
            }
        }
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @State private var selectedTimeRange: TimeRange = .monthly
    
    private var dailyData: [(date: Date, income: Double, expense: Double)] {
        viewModel.dailySpending(for: selectedTimeRange)
    }
    
    private var daysInRange: Double {
        switch selectedTimeRange {
        case .daily: return 1
        case .weekly: return 7
        case .monthly: return 30
        case .yearly: return 365
        }
    }
    
    private var incomeChange: Double { viewModel.incomeDeltaPercent * 100 }
    private var expenseChange: Double { viewModel.expenseDeltaPercent * 100 }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                TimeScopeSelector(selected: $selectedTimeRange, showAllOptions: true)
                    .padding(.horizontal, 16)
                
                analyticsOverviewSection
                analyticsChartsSection
                analyticsKeyMetricsSection
                analyticsCategoriesSection
                analyticsActivitySection
                analyticsForecastSection
                analyticsInsightsSection
            }
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Analytics")
    }
    
    @ViewBuilder
    private var analyticsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(selectedTimeRange.shortTitle) Overview")
                .font(.system(size: 15, weight: .semibold))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                AnalyticsStatCard(icon: "arrow.down.circle.fill", title: "Income", value: formatCurrency(viewModel.currentRangeIncome, currency: viewModel.appState.selectedCurrency), color: Theme.Colors.income, delta: incomeChange)
                AnalyticsStatCard(icon: "arrow.up.circle.fill", title: "Expenses", value: formatCurrency(viewModel.currentRangeExpenses, currency: viewModel.appState.selectedCurrency), color: Theme.Colors.expense, delta: expenseChange)
                AnalyticsStatCard(icon: "banknote.fill", title: "Net Savings", value: formatCurrency(viewModel.currentRangeNet, currency: viewModel.appState.selectedCurrency), color: viewModel.currentRangeNet >= 0 ? Theme.Colors.income : Theme.Colors.expense)
                AnalyticsStatCard(icon: "percent", title: "Savings Rate", value: String(format: "%.0f%%", max(0, viewModel.savingsRate)), color: viewModel.savingsRate >= 20 ? Theme.Colors.income : Theme.Colors.recurring)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var analyticsChartsSection: some View {
        if dailyData.count > 1 {
            AnalyticsIncomeExpenseChart(dailyData: dailyData, currency: viewModel.appState.selectedCurrency)
                .padding(.horizontal, 16)
            
            AnalyticsCumulativeChart(dailyData: dailyData, currency: viewModel.appState.selectedCurrency)
                .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private var analyticsKeyMetricsSection: some View {
        let currency = viewModel.appState.selectedCurrency
        VStack(alignment: .leading, spacing: 14) {
            Text("Key Metrics")
                .font(.system(size: 15, weight: .semibold))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricMiniCard(label: "Daily Avg", value: formatCurrency(viewModel.currentRangeExpenses / max(1, daysInRange), currency: currency), icon: "calendar", color: Theme.Colors.expense)
                MetricMiniCard(label: "Avg / Txn", value: formatCurrency(viewModel.averageTransactionAmount, currency: currency), icon: "divide.circle.fill", color: Theme.Colors.primary)
                MetricMiniCard(label: "Most Active", value: viewModel.mostActiveDay ?? "—", icon: "flame.fill", color: Theme.Colors.recurring)
            }
            
            if let largest = viewModel.largestExpense {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.recurring)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Largest Expense").font(.system(size: 12)).foregroundColor(Color(uiColor: .secondaryLabel))
                        Text("\(largest.title.isEmpty ? "Untitled" : largest.title) — \(formatCurrency(largest.amount, currency: currency))")
                            .font(.system(size: 13, weight: .medium))
                    }
                    Spacer()
                }
                .padding(12)
                .background(Theme.Colors.recurring.opacity(0.06))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var analyticsCategoriesSection: some View {
        let spending = viewModel.spendingByCategory()
        let income = viewModel.incomeByCategory()
        let currency = viewModel.appState.selectedCurrency
        
        if !spending.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Spending by Category").font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text("\(spending.count) categories").font(.system(size: 12)).foregroundColor(Color(uiColor: .secondaryLabel))
                }
                
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(spending.prefix(6), id: \.category.id) { item in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.category.colorValue)
                                .frame(width: max(4, geo.size.width * CGFloat(item.percentage / 100)))
                        }
                    }
                }
                .frame(height: 10)
                
                ForEach(spending.prefix(8), id: \.category.id) { item in
                    CategorySpendingRow(category: item.category, amount: item.amount, percentage: item.percentage, currency: currency)
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(14)
            .padding(.horizontal, 16)
        }
        
        if !income.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Income by Category").font(.system(size: 15, weight: .semibold))
                ForEach(income.prefix(6), id: \.category.id) { item in
                    CategorySpendingRow(category: item.category, amount: item.amount, percentage: item.percentage, currency: currency)
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(14)
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private var analyticsActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transaction Activity").font(.system(size: 15, weight: .semibold))
            HStack(spacing: 16) {
                TransactionCountItem(count: viewModel.currentRangeTransactions.filter { $0.type == .income }.count, label: "Income", icon: "arrow.down.circle.fill", color: Theme.Colors.income)
                TransactionCountItem(count: viewModel.currentRangeTransactions.filter { $0.type == .expense }.count, label: "Expenses", icon: "arrow.up.circle.fill", color: Theme.Colors.expense)
                TransactionCountItem(count: viewModel.currentRangeTransactions.filter { $0.type == .transfer }.count, label: "Transfers", icon: "arrow.left.arrow.right.circle.fill", color: Theme.Colors.transfer)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var analyticsForecastSection: some View {
        if selectedTimeRange == .monthly, let forecast = viewModel.monthEndForecast {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.primary)
                    Text("Month Forecast")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text("\(forecast.daysRemaining)d left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(formatCurrency(forecast.projected, currency: viewModel.appState.selectedCurrency))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.expense)
                    Text("projected spend")
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .padding(.bottom, 2)
                }

                Text("~\(formatCurrency(forecast.dailyAvg, currency: viewModel.appState.selectedCurrency))/day avg")
                    .font(.system(size: 13))
                    .foregroundColor(Color(uiColor: .secondaryLabel))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(uiColor: .tertiarySystemFill))
                            .frame(height: 8)
                        Capsule()
                            .fill(Theme.Colors.primary)
                            .frame(width: geo.size.width * CGFloat(min(Double(forecast.daysPassed) / Double(max(forecast.daysPassed + forecast.daysRemaining, 1)), 1.0)), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var analyticsInsightsSection: some View {
        let insights = generateInsights()
        if !insights.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill").font(.system(size: 14)).foregroundColor(Color(hex: "AF52DE"))
                    Text("Smart Insights").font(.system(size: 15, weight: .semibold))
                }
                ForEach(insights, id: \.text) { insight in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: insight.icon).font(.system(size: 14)).foregroundColor(insight.color).frame(width: 24)
                        Text(insight.text).font(.system(size: 13)).foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    .padding(12)
                    .background(insight.color.opacity(0.05))
                    .cornerRadius(10)
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }
    
    private struct InsightItem: Hashable {
        let icon: String
        let text: String
        let color: Color
        
        static func == (lhs: InsightItem, rhs: InsightItem) -> Bool { lhs.text == rhs.text }
        func hash(into hasher: inout Hasher) { hasher.combine(text) }
    }
    
    private func generateInsights() -> [InsightItem] {
        var insights: [InsightItem] = []
        
        if viewModel.currentRangeExpenses > viewModel.currentRangeIncome && viewModel.currentRangeIncome > 0 {
            insights.append(InsightItem(icon: "exclamationmark.triangle.fill", text: "You're spending more than you earn this period. Consider cutting discretionary expenses.", color: Theme.Colors.expense))
        }
        
        if viewModel.savingsRate >= 20 {
            insights.append(InsightItem(icon: "star.fill", text: "Your savings rate of \(Int(viewModel.savingsRate))% is above the recommended 20%. Keep it up!", color: Theme.Colors.income))
        } else if viewModel.savingsRate > 0 {
            let gap = 20 - Int(viewModel.savingsRate)
            insights.append(InsightItem(icon: "arrow.up.right.circle.fill", text: "Your savings rate is \(Int(viewModel.savingsRate))%. Increasing it by \(gap)% would hit the recommended 20%.", color: Theme.Colors.recurring))
        }
        
        if let top = viewModel.spendingByCategory().first, top.percentage > 40 {
            insights.append(InsightItem(icon: "chart.pie.fill", text: "\(top.category.name) accounts for \(Int(top.percentage))% of your spending. Consider setting a budget for this category.", color: top.category.colorValue))
        }
        
        if expenseChange > 20 {
            insights.append(InsightItem(icon: "arrow.up.right", text: "Expenses increased \(Int(expenseChange))% compared to last period.", color: Theme.Colors.expense))
        } else if expenseChange < -10 {
            insights.append(InsightItem(icon: "arrow.down.right", text: "Expenses decreased \(Int(abs(expenseChange)))% compared to last period. Good progress!", color: Theme.Colors.income))
        }
        
        return insights
    }
}

struct MetricMiniCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Color(uiColor: .label))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.06))
        .cornerRadius(10)
    }
}

struct AnalyticsIncomeExpenseChart: View {
    let dailyData: [(date: Date, income: Double, expense: Double)]
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Income vs Expenses")
                .font(.system(size: 15, weight: .semibold))
            
            Chart {
                ForEach(dailyData, id: \.date) { entry in
                    BarMark(x: .value("Date", entry.date, unit: .day), y: .value("Amount", entry.income))
                        .foregroundStyle(Theme.Colors.income.gradient)
                        .cornerRadius(3)
                    BarMark(x: .value("Date", entry.date, unit: .day), y: .value("Amount", -entry.expense))
                        .foregroundStyle(Theme.Colors.expense.gradient)
                        .cornerRadius(3)
                }
                RuleMark(y: .value("Zero", 0))
                    .lineStyle(StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(uiColor: .separator))
            }
            .frame(height: 180)
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(Theme.Colors.income).frame(width: 8, height: 8)
                    Text("Income").font(.system(size: 11)).foregroundColor(Color(uiColor: .secondaryLabel))
                }
                HStack(spacing: 4) {
                    Circle().fill(Theme.Colors.expense).frame(width: 8, height: 8)
                    Text("Expenses").font(.system(size: 11)).foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct AnalyticsCumulativeChart: View {
    let dailyData: [(date: Date, income: Double, expense: Double)]
    let currency: String
    
    private var cumulativeData: [(date: Date, total: Double)] {
        var cumulative: Double = 0
        return dailyData.map { entry in
            cumulative += entry.expense
            return (date: entry.date, total: cumulative)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cumulative Spending")
                .font(.system(size: 15, weight: .semibold))
            
            Chart {
                ForEach(cumulativeData, id: \.date) { entry in
                    AreaMark(x: .value("Date", entry.date, unit: .day), y: .value("Total", entry.total))
                        .foregroundStyle(Theme.Colors.expense.opacity(0.15).gradient)
                    LineMark(x: .value("Date", entry.date, unit: .day), y: .value("Total", entry.total))
                        .foregroundStyle(Theme.Colors.expense)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .frame(height: 140)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct AnalyticsStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var delta: Double? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            if let delta, abs(delta) > 0.5 {
                HStack(spacing: 2) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(Int(abs(delta)))%")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(delta >= 0 ? (title == "Expenses" ? Theme.Colors.expense : Theme.Colors.income) : (title == "Expenses" ? Theme.Colors.income : Theme.Colors.expense))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

struct DailyAverageItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
            Text("per day")
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CategorySpendingRow: View {
    let category: Category
    let amount: Double
    let percentage: Double
    let currency: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(category.colorValue.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(category.colorValue)
            }
            
            Text(category.name)
                .font(.system(size: 15))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(amount, currency: currency))
                    .font(.system(size: 14, weight: .medium))
                
                Text(String(format: "%.0f%%", percentage))
                    .font(.system(size: 11))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
        }
    }
}

struct TransactionCountItem: View {
    let count: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text("\(count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color(uiColor: .label))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Goals List View
struct GoalsListView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @State private var showingAddGoal = false
    @State private var showingCalendar = false
    @State private var selectedGoalItem: Goal? = nil

    private var activeGoals: [Goal] { viewModel.goals.filter { $0.goalType == .goal && $0.progress < 100 } }
    private var completedGoals: [Goal] { viewModel.goals.filter { $0.goalType == .goal && $0.progress >= 100 } }
    
    var body: some View {
        List {
            if !activeGoals.isEmpty || !completedGoals.isEmpty {
                Section {
                    VStack(spacing: 14) {
                        HStack(spacing: 24) {
                            GoalSummaryItem(
                                value: "\(viewModel.goals.filter { $0.goalType == .goal }.count)",
                                label: "Goals",
                                color: Theme.Colors.goals
                            )
                            GoalSummaryItem(
                                value: "\(activeGoals.count)",
                                label: "Active",
                                color: Theme.Colors.primary
                            )
                            GoalSummaryItem(
                                value: "\(completedGoals.count)",
                                label: "Done",
                                color: Theme.Colors.income
                            )
                        }
                        
                        Button(action: { showingCalendar = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14))
                                Text("View Goals Calendar")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(Theme.Colors.primary)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Theme.Colors.primary.opacity(0.08))
                            .cornerRadius(10)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            
            if !activeGoals.isEmpty {
                Section("Active Goals") {
                    ForEach(activeGoals) { goal in
                        Button { selectedGoalItem = goal } label: {
                            GoalRowView(goal: goal, status: viewModel.status(for: goal), currency: viewModel.appState.selectedCurrency)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        for index in indexSet { viewModel.deleteGoal(activeGoals[index]) }
                    }
                }
            }

            if !completedGoals.isEmpty {
                Section("Completed") {
                    ForEach(completedGoals) { goal in
                        Button { selectedGoalItem = goal } label: {
                            GoalRowView(goal: goal, status: viewModel.status(for: goal), currency: viewModel.appState.selectedCurrency)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            if activeGoals.isEmpty && completedGoals.isEmpty {
                VStack(spacing: 14) {
                    Spacer().frame(height: 40)
                    
                    Image(systemName: "target")
                        .font(.system(size: 44))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                    
                    Text("No Goals Yet")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Text("Create savings goals to track\nyour progress towards targets")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showingAddGoal = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Goal")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddGoal = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(item: $selectedGoalItem) { goal in
            GoalDetailView(viewModel: viewModel, goal: goal)
        }
        .sheet(isPresented: $showingAddGoal) { AddGoalView(viewModel: viewModel) }
        .sheet(isPresented: $showingCalendar) { GoalsCalendarView(viewModel: viewModel) }
    }
}

// MARK: - Savings Pots List View (More tab)
struct SavingsPotsListView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @State private var selectedPot: Goal?
    @State private var showAddPot = false

    private var pots: [Goal] {
        viewModel.goals.filter { $0.goalType == .envelope }
    }

    var body: some View {
        List {
            if pots.isEmpty {
                VStack(spacing: 14) {
                    Spacer().frame(height: 40)
                    Image(systemName: "tray.2.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                    Text("No Savings Pots")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Create pots for Savings, Investment, Charity, etc.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.center)
                    Button(action: { showAddPot = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Pot")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "30D158"))
                    }
                    .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(pots) { pot in
                        Button { selectedPot = pot } label: {
                            HStack(spacing: 12) {
                                Image(systemName: pot.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(pot.colorValue)
                                    .frame(width: 40, height: 40)
                                    .background(pot.colorValue.opacity(0.12))
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pot.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(uiColor: .label))
                                    Text("Savings Pot")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(uiColor: .secondaryLabel))
                                }
                                Spacer()
                                Text(formatCurrency(pot.currentAmount, currency: viewModel.appState.selectedCurrency))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(pot.colorValue)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indices in
                        for index in indices { viewModel.deleteGoal(pots[index]) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Savings Pots")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddPot = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddPot) {
            NavigationStack { QuickAddPotSheet(viewModel: viewModel) }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .navigationDestination(item: $selectedPot) { pot in
            GoalDetailView(viewModel: viewModel, goal: pot)
        }
    }
}

struct GoalSummaryItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }
}

struct GoalRowView: View {
    let goal: Goal
    let status: GoalStatus
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(goal.colorValue.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: goal.icon)
                        .font(.system(size: 16))
                        .foregroundColor(goal.colorValue)
                        .frame(width: 40, height: 40)

                    if goal.streak >= 2 {
                        HStack(spacing: 1) {
                            Text("🔥")
                                .font(.system(size: 8))
                            Text("\(goal.streak)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 3)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                        .offset(x: 6, y: -4)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.system(size: 15, weight: .semibold))

                    HStack(spacing: 4) {
                        Image(systemName: status.icon)
                            .font(.system(size: 10))
                        Text(status.label)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(status.color)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(goal.progress))%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(goal.colorValue)

                    Text(formatCurrency(goal.currentAmount, currency: currency))
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(uiColor: .tertiarySystemFill))
                        .frame(height: 6)

                    Capsule()
                        .fill(goal.colorValue)
                        .frame(width: geometry.size.width * CGFloat(min(goal.progress / 100, 1.0)), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 6)
    }
}

struct GoalDetailView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @Environment(\.dismiss) private var dismiss
    let goal: Goal
    @State private var showContribute = false
    @State private var contributeInitialWithdraw = false
    @State private var showEdit = false
    @State private var milestoneMessage: String? = nil

    private var currentGoal: Goal {
        viewModel.goals.first(where: { $0.id == goal.id }) ?? goal
    }

    private var potTransactions: [Transaction] {
        viewModel.transactions
            .filter { $0.goalId == currentGoal.id }
            .sorted { $0.date > $1.date }
            .prefix(20).map { $0 }
    }

    var body: some View {
        ZStack(alignment: .top) {
            List {
                Section {
                    VStack(spacing: 14) {
                        // Icon with streak badge
                        ZStack {
                            Circle()
                                .fill(currentGoal.colorValue.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: currentGoal.icon)
                                .font(.system(size: 36))
                                .foregroundColor(currentGoal.colorValue)
                        }
                        .overlay(alignment: .topTrailing) {
                            if currentGoal.streak >= 2 {
                                HStack(spacing: 2) {
                                    Text("🔥")
                                        .font(.system(size: 11))
                                    Text("\(currentGoal.streak)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 5)
                                .padding(.vertical, 3)
                                .background(Color.orange)
                                .clipShape(Capsule())
                                .offset(x: 8, y: -4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        Text(currentGoal.title)
                            .font(.system(size: 22, weight: .bold))

                        // Purchase: item name banner
                        if currentGoal.subType == .purchase, let item = currentGoal.itemName, !item.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "bag.fill")
                                    .font(.system(size: 12))
                                Text("Saving for: \(item)")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(currentGoal.colorValue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(currentGoal.colorValue.opacity(0.1))
                            .cornerRadius(20)
                        }

                        if currentGoal.targetAmount > 0 {
                            Text("\(Int(min(viewModel.effectiveCurrentAmount(for: currentGoal) / currentGoal.targetAmount * 100, 100)))% complete")
                                .font(.system(size: 14))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }

                        // Contribute buttons — hidden for linked goals
                        if currentGoal.linkedAccountId == nil && currentGoal.subType != .debtPayoff {
                            HStack(spacing: 12) {
                                Button(action: { contributeInitialWithdraw = false; showContribute = true }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                        Text("Add Money")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(currentGoal.colorValue)
                                    .cornerRadius(20)
                                }

                                if viewModel.effectiveCurrentAmount(for: currentGoal) > 0 {
                                    Button(action: { contributeInitialWithdraw = true; showContribute = true }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 14))
                                            Text("Withdraw")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(currentGoal.colorValue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(currentGoal.colorValue.opacity(0.1))
                                        .cornerRadius(20)
                                    }
                                }
                            }
                        } else if let linkedAccount = viewModel.accounts.first(where: { $0.id == currentGoal.linkedAccountId }) {
                            HStack(spacing: 6) {
                                Image(systemName: linkedAccount.icon)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: linkedAccount.color))
                                Text("Tracking \(linkedAccount.name)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(hex: linkedAccount.color))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color(hex: linkedAccount.color).opacity(0.1))
                            .cornerRadius(20)
                        } else if currentGoal.subType == .debtPayoff,
                                  let debtId = currentGoal.linkedDebtId,
                                  let debt = viewModel.debts.first(where: { $0.id == debtId }) {
                            HStack(spacing: 6) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.red)
                                Text("Tracking: \(debt.title)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                // Streak card
                if currentGoal.goalType == .goal && currentGoal.streak > 0 {
                    Section {
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("🔥")
                                        .font(.system(size: 22))
                                    Text("\(currentGoal.streak)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.orange)
                                }
                                Text("week streak")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(uiColor: .secondaryLabel))
                            }
                            .frame(maxWidth: .infinity)

                            Divider().frame(height: 44)

                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.yellow)
                                    Text("\(currentGoal.longestStreak)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(uiColor: .label))
                                }
                                Text("best streak")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(uiColor: .secondaryLabel))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section("Progress") {
                    let effectiveAmount = viewModel.effectiveCurrentAmount(for: currentGoal)
                    let isLinked = currentGoal.linkedAccountId != nil

                    HStack {
                        Text(isLinked ? "Account Balance" : "Current Amount")
                        Spacer()
                        Text(formatCurrency(effectiveAmount, currency: viewModel.appState.selectedCurrency))
                            .foregroundColor(Theme.Colors.income)
                            .contentTransition(.numericText())
                    }

                    if currentGoal.targetAmount > 0 {
                        HStack {
                            Text("Target Amount")
                            Spacer()
                            Text(formatCurrency(currentGoal.targetAmount, currency: viewModel.appState.selectedCurrency))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }

                        HStack {
                            Text("Remaining")
                            Spacer()
                            Text(formatCurrency(max(0, currentGoal.targetAmount - effectiveAmount), currency: viewModel.appState.selectedCurrency))
                                .foregroundColor(Color(uiColor: .label))
                        }

                        // Weekly target to stay on track
                        if let deadline = currentGoal.deadline, currentGoal.linkedAccountId == nil {
                            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
                            let weeksLeft = max(1, Double(daysLeft) / 7.0)
                            let remaining = max(0, currentGoal.targetAmount - effectiveAmount)
                            let weeklyNeeded = remaining / weeksLeft
                            if weeklyNeeded > 0 {
                                HStack {
                                    Text("Weekly target")
                                    Spacer()
                                    Text(formatCurrency(weeklyNeeded, currency: viewModel.appState.selectedCurrency))
                                        .foregroundColor(Theme.Colors.primary)
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                        }

                        if let eta = viewModel.goalETA(for: currentGoal) {
                            HStack {
                                Text("Est. completion")
                                Spacer()
                                Text(eta, style: .date)
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }

                        // Emergency fund: months coverage badge
                        if currentGoal.subType == .emergency {
                            let monthly = viewModel.emergencyFundSuggestedTarget / 3
                            let months = monthly > 0 ? effectiveAmount / monthly : 0
                            HStack {
                                Text("Coverage")
                                Spacer()
                                Text(String(format: "%.1f months", months))
                                    .foregroundColor(months >= 3 ? Theme.Colors.income : Theme.Colors.expense)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                        }

                        GeometryReader { geometry in
                            let pct = currentGoal.targetAmount > 0 ? min(effectiveAmount / currentGoal.targetAmount, 1.0) : 0
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(uiColor: .tertiarySystemFill))
                                    .frame(height: 8)
                                Capsule()
                                    .fill(currentGoal.colorValue)
                                    .frame(width: geometry.size.width * CGFloat(pct), height: 8)
                                    .animation(.spring, value: effectiveAmount)
                            }
                        }
                        .frame(height: 8)
                        .listRowBackground(Color.clear)
                    }
                }

                if let deadline = currentGoal.deadline {
                    Section("Deadline") {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Theme.Colors.primary)
                            Text(formatGoalDate(deadline))
                        }
                    }
                }

                // Recent Activity
                Section("Recent Activity") {
                    if potTransactions.isEmpty {
                        Text("No activity yet")
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(potTransactions) { tx in
                            let isWithdrawal = tx.accountId == currentGoal.id
                            let account = viewModel.getAccount(by: isWithdrawal ? (tx.toAccountId ?? tx.accountId) : tx.accountId)
                            HStack(spacing: 12) {
                                Image(systemName: currentGoal.icon)
                                    .font(.system(size: 15))
                                    .foregroundColor(currentGoal.colorValue)
                                    .frame(width: 36, height: 36)
                                    .background(currentGoal.colorValue.opacity(0.12))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tx.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(uiColor: .label))
                                        .lineLimit(1)
                                    HStack(spacing: 4) {
                                        if let acc = account {
                                            Text(acc.name)
                                                .foregroundColor(Color(uiColor: .secondaryLabel))
                                        }
                                        Text("•")
                                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                                        Text(tx.date, style: .date)
                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                    }
                                    .font(.system(size: 12))
                                }

                                Spacer()

                                Text("\(isWithdrawal ? "-" : "+")\(formatCurrency(tx.amount, currency: viewModel.appState.selectedCurrency))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(isWithdrawal ? Theme.Colors.expense : Theme.Colors.income)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        viewModel.deleteGoal(goal)
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete \(currentGoal.goalType == .envelope ? "Pot" : "Goal")")
                        }
                    }
                }
            }

            // Milestone celebration banner
            if let msg = milestoneMessage {
                VStack {
                    HStack(spacing: 10) {
                        Text("🎉")
                            .font(.system(size: 20))
                        Text(msg)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(currentGoal.colorValue)
                    .cornerRadius(16)
                    .shadow(color: currentGoal.colorValue.opacity(0.4), radius: 8, y: 4)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .navigationTitle(currentGoal.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showContribute) {
            GoalContributeSheet(viewModel: viewModel, goal: currentGoal,
                                initialIsWithdraw: contributeInitialWithdraw)
        }
        .sheet(isPresented: $showEdit) {
            EditGoalView(viewModel: viewModel, goal: currentGoal)
        }
        .onChange(of: viewModel.goals.map(\.id)) { _, newIds in
            if !newIds.contains(goal.id) { dismiss() }
        }
        .onChange(of: viewModel.recentMilestone?.goalId) { _, goalId in
            guard goalId == goal.id, let m = viewModel.recentMilestone else { return }
            let pct = m.pct
            let msg: String
            switch pct {
            case 100: msg = "Goal complete! You did it!"
            case 75:  msg = "75% there! Almost done!"
            case 50:  msg = "Halfway there! Keep it up!"
            default:  msg = "Great start! 25% of the way there."
            }
            withAnimation(.spring) { milestoneMessage = msg }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation { milestoneMessage = nil }
                viewModel.recentMilestone = nil
            }
        }
    }

    private func formatGoalDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Goal Contribute Sheet
struct GoalContributeSheet: View {
    @ObservedObject var viewModel: BalancedViewModel
    let goal: Goal
    let initialIsWithdraw: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var isWithdraw = false
    @State private var selectedAccountId: UUID?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(goal.colorValue.opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: goal.icon)
                                .font(.system(size: 24))
                                .foregroundColor(goal.colorValue)
                        }

                        Text(goal.title)
                            .font(.system(size: 17, weight: .semibold))

                        Text(formatCurrency(goal.currentAmount, currency: viewModel.appState.selectedCurrency))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(goal.colorValue)

                        Picker("", selection: $isWithdraw) {
                            Text("Add").tag(false)
                            Text("Withdraw").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 40)

                        // Account picker — None available for both Add and Withdraw
                        VStack(alignment: .leading, spacing: 8) {
                            Text(isWithdraw ? "RETURN TO" : "FROM ACCOUNT")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    let noneSelected = selectedAccountId == nil
                                    Button(action: { withAnimation(.snappy) { selectedAccountId = nil }; Haptics.selection() }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(noneSelected ? .white : Color(uiColor: .secondaryLabel))
                                                .frame(width: 36, height: 36)
                                                .background(noneSelected ? Color(uiColor: .secondaryLabel) : Color(uiColor: .tertiarySystemFill))
                                                .clipShape(Circle())
                                            Text("None")
                                                .font(.system(size: 11, weight: noneSelected ? .semibold : .regular))
                                                .foregroundColor(noneSelected ? Color(uiColor: .label) : Color(uiColor: .tertiaryLabel))
                                                .lineLimit(1)
                                        }
                                        .frame(width: 64)
                                    }
                                    .buttonStyle(.plain)

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
                                .padding(.horizontal, 20)
                            }
                        }

                        HStack(spacing: 4) {
                            Text(currencySymbol)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color(uiColor: .label).opacity(amount.isEmpty ? 0.25 : 1))
                            TextField("0", text: $amount)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color(uiColor: .label))
                        }
                        .frame(maxWidth: 200)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                Button(action: contribute) {
                    Text(isWithdraw ? "Withdraw" : "Add Money")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(canContribute ? goal.colorValue : goal.colorValue.opacity(0.3))
                        .cornerRadius(14)
                }
                .disabled(!canContribute)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle(isWithdraw ? "Withdraw" : "Add Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                isWithdraw = initialIsWithdraw
                selectedAccountId = nil
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private var currencySymbol: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = viewModel.appState.selectedCurrency
        return f.currencySymbol ?? "$"
    }

    private var canContribute: Bool {
        guard let value = Double(amount), value > 0 else { return false }
        if isWithdraw && value > goal.currentAmount { return false }
        return true
    }

    private func contribute() {
        guard let value = Double(amount), value > 0 else { return }
        let adjustedAmount = isWithdraw ? -value : value
        viewModel.contributeToGoal(goal, amount: adjustedAmount, fromAccountId: selectedAccountId)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Edit Goal View
struct EditGoalView: View {
    @ObservedObject var viewModel: BalancedViewModel
    let goal: Goal
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var targetAmount: String
    @State private var itemName: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var selectedIcon: String
    @State private var selectedColorIndex: Int
    @State private var showAllIcons = false
    @State private var linkedAccountId: UUID?
    @State private var linkedDebtId: UUID?

    private let goalIcons = [
        "star.fill", "target", "banknote.fill", "chart.line.uptrend.xyaxis",
        "heart.fill", "graduationcap.fill", "airplane", "house.fill",
        "gift.fill", "leaf.fill", "car.fill", "laptopcomputer",
        "suitcase.fill", "map.fill", "globe.americas.fill", "bed.double.fill",
        "fork.knife", "cart.fill", "bag.fill", "tshirt.fill",
        "dumbbell.fill", "figure.run", "pawprint.fill", "dog.fill",
        "cat.fill", "camera.fill", "music.note", "gamecontroller.fill",
        "book.fill", "paintbrush.fill", "wrench.fill", "hammer.fill",
        "briefcase.fill", "building.columns.fill", "creditcard.fill", "wallet.pass.fill",
        "phone.fill", "tv.fill", "bicycle", "bus.fill",
        "crown.fill", "sparkles", "bolt.fill", "flame.fill",
        "tree.fill", "mountain.2.fill", "sun.max.fill", "moon.fill",
    ]

    init(viewModel: BalancedViewModel, goal: Goal) {
        self.viewModel = viewModel
        self.goal = goal
        _title = State(initialValue: goal.title)
        _targetAmount = State(initialValue: goal.targetAmount > 0 ? String(format: "%.0f", goal.targetAmount) : "")
        _itemName = State(initialValue: goal.itemName ?? "")
        _hasDeadline = State(initialValue: goal.deadline != nil)
        _deadline = State(initialValue: goal.deadline ?? Date().addingTimeInterval(86400 * 30))
        _selectedIcon = State(initialValue: goal.icon)
        _linkedAccountId = State(initialValue: goal.linkedAccountId)
        _linkedDebtId = State(initialValue: goal.linkedDebtId)

        var colorIdx = 0
        for (index, color) in Theme.Colors.categoryColors.enumerated() {
            if let hex = color.toHex(), hex.uppercased() == goal.color.uppercased() {
                colorIdx = index
                break
            }
        }
        _selectedColorIndex = State(initialValue: colorIdx)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Preview
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.categoryColors[selectedColorIndex].opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: selectedIcon)
                                .font(.system(size: 24))
                                .foregroundColor(Theme.Colors.categoryColors[selectedColorIndex])
                        }
                        Text(title.isEmpty ? (goal.goalType == .envelope ? "Pot Name" : "Goal Name") : title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(title.isEmpty ? Color(uiColor: .tertiaryLabel) : Color(uiColor: .label))

                        Text(goal.goalType == .envelope ? "Savings Pot" : goal.subType.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    .padding(.vertical, 16)

                    // Details
                    VStack(spacing: 0) {
                        FormRow(label: "Title") {
                            TextField("Title", text: $title)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.trailing)
                        }

                        if goal.goalType == .goal {
                            // Purchase: item name
                            if goal.subType == .purchase {
                                Divider().padding(.leading, 16)
                                FormRow(label: "Item") {
                                    TextField("Item name", text: $itemName)
                                        .font(.system(size: 15))
                                        .multilineTextAlignment(.trailing)
                                }
                            }

                            // Balance: account picker
                            if goal.subType == .balance {
                                Divider().padding(.leading, 16)
                                FormRow(label: "Link Account") {
                                    Picker("Account", selection: $linkedAccountId) {
                                        Text("None").tag(UUID?.none)
                                        ForEach(viewModel.accounts) { account in
                                            Text(account.name).tag(UUID?.some(account.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .font(.system(size: 15))
                                }
                                if linkedAccountId != nil {
                                    HStack(spacing: 6) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.Colors.primary)
                                        Text("Progress tracks the account's live balance")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 10)
                                }
                            }

                            // Debt payoff: debt picker
                            if goal.subType == .debtPayoff {
                                Divider().padding(.leading, 16)
                                FormRow(label: "Linked Debt") {
                                    Picker("Debt", selection: $linkedDebtId) {
                                        Text("None").tag(UUID?.none)
                                        ForEach(viewModel.activeDebts) { debt in
                                            Text(debt.title).tag(UUID?.some(debt.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .font(.system(size: 15))
                                }
                            }

                            // Target amount (not for debtPayoff / emergency)
                            if goal.subType != .debtPayoff && goal.subType != .emergency {
                                Divider().padding(.leading, 16)
                                FormRow(label: "Target") {
                                    HStack(spacing: 4) {
                                        Text("$")
                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                        TextField("Target Amount", text: $targetAmount)
                                            .keyboardType(.decimalPad)
                                            .font(.system(size: 15))
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                            }
                        }
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .padding(.horizontal, 16)

                    if goal.goalType == .goal && goal.subType != .debtPayoff {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Set Deadline")
                                    .font(.system(size: 15))
                                Spacer()
                                Toggle("", isOn: $hasDeadline)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            if hasDeadline {
                                Divider().padding(.leading, 16)
                                DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }

                    // Icon
                    PickerSection(title: "Icon") {
                        let visibleIcons = showAllIcons ? goalIcons : Array(goalIcons.prefix(24))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(visibleIcons, id: \.self) { icon in
                                IconPickerItem(
                                    icon: icon,
                                    color: Theme.Colors.categoryColors[selectedColorIndex],
                                    isSelected: selectedIcon == icon,
                                    action: { selectedIcon = icon; Haptics.selection() }
                                )
                            }
                        }
                        if goalIcons.count > 24 {
                            Button {
                                withAnimation(.snappy) { showAllIcons.toggle() }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(showAllIcons ? "Show Less" : "Show More")
                                        .font(.system(size: 13, weight: .medium))
                                    Image(systemName: showAllIcons ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(Theme.Colors.primary)
                                .padding(.top, 6)
                            }
                        }
                    }

                    // Color
                    PickerSection(title: "Color") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                            ForEach(0..<Theme.Colors.categoryColors.count, id: \.self) { index in
                                ColorPickerItem(
                                    color: Theme.Colors.categoryColors[index],
                                    isSelected: selectedColorIndex == index,
                                    action: { selectedColorIndex = index; Haptics.selection() }
                                )
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Edit \(goal.goalType == .envelope ? "Pot" : "Goal")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        var updated = goal
        updated.title = title
        updated.icon = selectedIcon
        updated.color = Theme.Colors.categoryColors[selectedColorIndex].toHex() ?? goal.color
        if goal.goalType == .goal {
            if goal.subType != .debtPayoff && goal.subType != .emergency {
                if let amount = Double(targetAmount) { updated.targetAmount = amount }
            }
            updated.deadline = hasDeadline ? deadline : nil
            updated.linkedAccountId = linkedAccountId
            updated.linkedDebtId = linkedDebtId
            updated.itemName = itemName.isEmpty ? nil : itemName
        }
        viewModel.updateGoal(updated)
        Haptics.success()
        dismiss()
    }
}

struct GoalsCalendarView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.goals.filter { $0.deadline != nil }.sorted { ($0.deadline ?? Date()) < ($1.deadline ?? Date()) }) { goal in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(goal.colorValue.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: goal.icon)
                                .font(.system(size: 14))
                                .foregroundColor(goal.colorValue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.title)
                                .font(.system(size: 15, weight: .medium))
                            if let deadline = goal.deadline {
                                Text(formatCalendarDate(deadline))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(uiColor: .secondaryLabel))
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(Int(goal.progress))%")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(goal.colorValue)
                    }
                }
                
                if viewModel.goals.filter({ $0.deadline != nil }).isEmpty {
                    Text("No goals with deadlines set")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Goals Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func formatCalendarDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Add Goal View
struct AddGoalView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var goalType: GoalType = .goal
    @State private var subType: GoalSubType = .savings
    @State private var title = ""
    @State private var targetAmount = ""
    @State private var itemName = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400 * 30)
    @State private var selectedColorIndex = 0
    @State private var selectedIcon = "star.fill"
    @State private var showAllIcons = false
    @State private var linkedAccountId: UUID? = nil
    @State private var linkedDebtId: UUID? = nil
    @State private var emergencyMonths: Int = 3

    private let goalIcons = [
        "star.fill", "target", "banknote.fill", "chart.line.uptrend.xyaxis",
        "heart.fill", "graduationcap.fill", "airplane", "house.fill",
        "gift.fill", "leaf.fill", "car.fill", "laptopcomputer",
        "suitcase.fill", "map.fill", "globe.americas.fill", "bed.double.fill",
        "fork.knife", "cart.fill", "bag.fill", "tshirt.fill",
        "dumbbell.fill", "figure.run", "pawprint.fill", "dog.fill",
        "cat.fill", "camera.fill", "music.note", "gamecontroller.fill",
        "book.fill", "paintbrush.fill", "wrench.fill", "hammer.fill",
        "briefcase.fill", "building.columns.fill", "creditcard.fill", "wallet.pass.fill",
        "phone.fill", "tv.fill", "bicycle", "bus.fill",
        "crown.fill", "sparkles", "bolt.fill", "flame.fill",
        "tree.fill", "mountain.2.fill", "sun.max.fill", "moon.fill",
    ]

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.appState.selectedCurrency
        return formatter.currencySymbol ?? "$"
    }

    private var canAdd: Bool {
        guard !title.isEmpty else { return false }
        if goalType == .envelope { return true }
        switch subType {
        case .savings:    return !targetAmount.isEmpty
        case .purchase:   return !itemName.isEmpty && !targetAmount.isEmpty
        case .balance:    return linkedAccountId != nil && !targetAmount.isEmpty
        case .emergency:  return true
        case .debtPayoff: return linkedDebtId != nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Goal type: Goal vs Pot
                    Picker("Type", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    // Sub-type cards (goals only)
                    if goalType == .goal {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(GoalSubType.allCases, id: \.self) { type in
                                    GoalSubTypeCard(
                                        subType: type,
                                        isSelected: subType == type,
                                        action: {
                                            withAnimation(.snappy) { subType = type }
                                            // Auto-set icon to match sub-type
                                            selectedIcon = type.icon
                                            Haptics.selection()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Preview
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.categoryColors[selectedColorIndex].opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: selectedIcon)
                                .font(.system(size: 24))
                                .foregroundColor(Theme.Colors.categoryColors[selectedColorIndex])
                        }
                        Text(title.isEmpty ? (goalType == .envelope ? "Pot Name" : "Goal Name") : title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(title.isEmpty ? Color(uiColor: .tertiaryLabel) : Color(uiColor: .label))

                        Text(goalType == .envelope ? "Savings Pot" : subType.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    .padding(.vertical, 16)

                    // Details form
                    VStack(spacing: 0) {
                        FormRow(label: "Name") {
                            TextField(goalType == .goal ? "Goal Title" : "Pot Name (e.g., Savings)", text: $title)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.trailing)
                        }

                        if goalType == .goal {
                            // Purchase: item name
                            if subType == .purchase {
                                Divider().padding(.leading, 16)
                                FormRow(label: "Item") {
                                    TextField("What are you saving for?", text: $itemName)
                                        .font(.system(size: 15))
                                        .multilineTextAlignment(.trailing)
                                }
                            }

                            // Balance: account picker
                            if subType == .balance {
                                Divider().padding(.leading, 16)
                                FormRow(label: "Account") {
                                    Picker("Account", selection: $linkedAccountId) {
                                        Text("Select Account").tag(UUID?.none)
                                        ForEach(viewModel.accounts) { account in
                                            Text(account.name).tag(UUID?.some(account.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .font(.system(size: 15))
                                }
                                if linkedAccountId != nil {
                                    HStack(spacing: 6) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.Colors.primary)
                                        Text("Progress will automatically track the account's live balance")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                            }

                            // Debt payoff: debt picker
                            if subType == .debtPayoff {
                                Divider().padding(.leading, 16)
                                FormRow(label: "Debt") {
                                    Picker("Debt", selection: $linkedDebtId) {
                                        Text("Select Debt").tag(UUID?.none)
                                        ForEach(viewModel.activeDebts) { debt in
                                            Text(debt.title).tag(UUID?.some(debt.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .font(.system(size: 15))
                                }
                                if let debtId = linkedDebtId,
                                   let debt = viewModel.activeDebts.first(where: { $0.id == debtId }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.Colors.primary)
                                        Text("Outstanding: \(formatCurrency(debt.totalAmount - debt.paidAmount, currency: viewModel.appState.selectedCurrency))")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                            }

                            // Emergency fund: months selector + computed target
                            if subType == .emergency {
                                Divider().padding(.leading, 16)
                                FormRow(label: "Months cushion") {
                                    Picker("Months", selection: $emergencyMonths) {
                                        Text("3 months").tag(3)
                                        Text("6 months").tag(6)
                                    }
                                    .pickerStyle(.menu)
                                    .font(.system(size: 15))
                                }
                                let suggested = viewModel.emergencyFundSuggestedTarget / 3 * Double(emergencyMonths)
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(Theme.Colors.primary)
                                    Text("Suggested target: \(formatCurrency(suggested, currency: viewModel.appState.selectedCurrency)) based on your spending")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(uiColor: .secondaryLabel))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }

                            // Target amount (savings, purchase, balance — not emergency/debtPayoff)
                            if subType == .savings || subType == .purchase || subType == .balance {
                                Divider().padding(.leading, 16)
                                FormRow(label: "Target") {
                                    HStack(spacing: 4) {
                                        Text(currencySymbol)
                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                        TextField("Target Amount", text: $targetAmount)
                                            .keyboardType(.decimalPad)
                                            .font(.system(size: 15))
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                            }
                        }
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .padding(.horizontal, 16)

                    // Deadline (goals only, not debtPayoff or emergency)
                    if goalType == .goal && subType != .debtPayoff {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Set Deadline")
                                    .font(.system(size: 15))
                                Spacer()
                                Toggle("", isOn: $hasDeadline)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            if hasDeadline {
                                Divider().padding(.leading, 16)
                                DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }

                    // Icon
                    PickerSection(title: "Icon") {
                        let visibleIcons = showAllIcons ? goalIcons : Array(goalIcons.prefix(24))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(visibleIcons, id: \.self) { icon in
                                IconPickerItem(
                                    icon: icon,
                                    color: Theme.Colors.categoryColors[selectedColorIndex],
                                    isSelected: selectedIcon == icon,
                                    action: { selectedIcon = icon; Haptics.selection() }
                                )
                            }
                        }
                        if goalIcons.count > 24 {
                            Button {
                                withAnimation(.snappy) { showAllIcons.toggle() }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(showAllIcons ? "Show Less" : "Show More")
                                        .font(.system(size: 13, weight: .medium))
                                    Image(systemName: showAllIcons ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(Theme.Colors.primary)
                                .padding(.top, 6)
                            }
                        }
                    }

                    // Color
                    PickerSection(title: "Color") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                            ForEach(0..<Theme.Colors.categoryColors.count, id: \.self) { index in
                                ColorPickerItem(
                                    color: Theme.Colors.categoryColors[index],
                                    isSelected: selectedColorIndex == index,
                                    action: { selectedColorIndex = index; Haptics.selection() }
                                )
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(goalType == .goal ? "New Goal" : "New Savings Pot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addGoal() }
                        .fontWeight(.semibold)
                        .disabled(!canAdd)
                }
            }
        }
    }

    private func addGoal() {
        let colorHex = Theme.Colors.categoryColors[selectedColorIndex].toHex() ?? "#007AFF"

        if goalType == .envelope {
            let pot = Goal(title: title, icon: selectedIcon, color: colorHex, goalType: .envelope)
            viewModel.addGoal(pot)
        } else {
            let resolvedTarget: Double
            let resolvedLinkedAccount: UUID?
            let resolvedLinkedDebt: UUID?
            let resolvedItemName: String?

            switch subType {
            case .savings:
                resolvedTarget = Double(targetAmount) ?? 0
                resolvedLinkedAccount = nil
                resolvedLinkedDebt = nil
                resolvedItemName = nil
            case .purchase:
                resolvedTarget = Double(targetAmount) ?? 0
                resolvedLinkedAccount = nil
                resolvedLinkedDebt = nil
                resolvedItemName = itemName.isEmpty ? nil : itemName
            case .balance:
                resolvedTarget = Double(targetAmount) ?? 0
                resolvedLinkedAccount = linkedAccountId
                resolvedLinkedDebt = nil
                resolvedItemName = nil
            case .emergency:
                let base = viewModel.emergencyFundSuggestedTarget / 3 * Double(emergencyMonths)
                resolvedTarget = max(base, 1)
                resolvedLinkedAccount = nil
                resolvedLinkedDebt = nil
                resolvedItemName = nil
            case .debtPayoff:
                let debt = viewModel.activeDebts.first(where: { $0.id == linkedDebtId })
                resolvedTarget = debt.map { $0.totalAmount - $0.paidAmount } ?? 0
                resolvedLinkedAccount = nil
                resolvedLinkedDebt = linkedDebtId
                resolvedItemName = nil
            }

            let goal = Goal(
                title: title,
                targetAmount: resolvedTarget,
                deadline: hasDeadline ? deadline : nil,
                icon: selectedIcon,
                color: colorHex,
                goalType: .goal,
                linkedAccountId: resolvedLinkedAccount,
                subType: subType,
                itemName: resolvedItemName,
                linkedDebtId: resolvedLinkedDebt
            )
            viewModel.addGoal(goal)
        }

        Haptics.success()
        dismiss()
    }
}

// MARK: - Goal Sub-Type Card
struct GoalSubTypeCard: View {
    let subType: GoalSubType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: subType.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : Theme.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.1))
                    .clipShape(Circle())

                Text(subType.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? Theme.Colors.primary : Color(uiColor: .label))

                Text(subType.description)
                    .font(.system(size: 10))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 110)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Theme.Colors.primary.opacity(0.08) : Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Financial Health View
struct FinancialHealthView: View {
    @ObservedObject var viewModel: BalancedViewModel
    
    private var savingsRateScore: Int {
        if viewModel.savingsRate >= 20 { return 30 }
        if viewModel.savingsRate >= 10 { return 20 }
        if viewModel.savingsRate > 0 { return 10 }
        return 0
    }
    
    private var budgetAdherenceScore: Int {
        let budgetedCategories = viewModel.categories.filter { ($0.budget ?? 0) > 0 }
        guard !budgetedCategories.isEmpty else { return 0 }
        let onBudget = budgetedCategories.filter { cat in
            let spent = viewModel.spendingForCategory(cat)
            return spent <= (cat.budget ?? 0)
        }
        let ratio = Double(onBudget.count) / Double(budgetedCategories.count)
        if ratio >= 0.8 { return 15 }
        if ratio >= 0.5 { return 10 }
        return 5
    }
    
    private var goalsScore: Int {
        if viewModel.goals.isEmpty { return 0 }
        let progressingGoals = viewModel.goals.filter { $0.progress > 0 }
        if !progressingGoals.isEmpty { return 15 }
        return 8
    }
    
    private var trackingScore: Int {
        let txCount = viewModel.transactions.count
        if txCount >= 50 { return 15 }
        if txCount >= 20 { return 10 }
        if txCount > 0 { return 5 }
        return 0
    }
    
    private var diversificationScore: Int {
        let accountCount = viewModel.accounts.count
        if accountCount >= 3 { return 10 }
        if accountCount >= 2 { return 5 }
        return 0
    }
    
    private var spendingTrendScore: Int {
        if viewModel.expenseDeltaPercent < -0.05 { return 15 }
        if viewModel.expenseDeltaPercent <= 0.05 { return 10 }
        if viewModel.expenseDeltaPercent <= 0.2 { return 5 }
        return 0
    }
    
    private var debtBurdenScore: Int {
        if viewModel.activeDebts.isEmpty { return 15 }
        if !viewModel.overdueDebts.isEmpty { return 0 }
        let monthlyOwed = viewModel.totalOutstandingOwed / 12
        if viewModel.monthlyIncome > 0 && monthlyOwed < viewModel.monthlyIncome * 0.15 { return 10 }
        return 5
    }

    private var healthScore: Int {
        min(100, savingsRateScore + budgetAdherenceScore + goalsScore + trackingScore + diversificationScore + spendingTrendScore + debtBurdenScore)
    }
    
    private var healthColor: Color {
        if healthScore >= 80 { return Theme.Colors.income }
        if healthScore >= 60 { return Theme.Colors.goals }
        if healthScore >= 40 { return Theme.Colors.recurring }
        return Theme.Colors.expense
    }
    
    private var healthLabel: String {
        if healthScore >= 80 { return "Excellent" }
        if healthScore >= 60 { return "Good" }
        if healthScore >= 40 { return "Fair" }
        return "Needs Work"
    }
    
    private var scoreHistory: [(label: String, score: Int)] {
        [
            ("Savings", savingsRateScore),
            ("Budget", budgetAdherenceScore),
            ("Goals", goalsScore),
            ("Tracking", trackingScore),
            ("Accounts", diversificationScore),
            ("Trend", spendingTrendScore),
            ("Debts", debtBurdenScore)
        ]
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                healthScoreRing
                netWorthCard
                healthChartSection
                healthBreakdownSection
                healthAllocationSection
                healthTipsSection
            }
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Financial Health")
    }
    
    @ViewBuilder
    private var healthScoreRing: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color(uiColor: .tertiarySystemFill), lineWidth: 14)
                    .frame(width: 170, height: 170)
                Circle()
                    .trim(from: 0, to: CGFloat(healthScore) / 100)
                    .stroke(healthColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8), value: healthScore)
                VStack(spacing: 2) {
                    Text("\(healthScore)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(healthColor)
                    Text(healthLabel)
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }
            Text("Your Financial Health Score")
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var netWorthCard: some View {
        let netWorth = viewModel.netWorth
        let currency = viewModel.appState.selectedCurrency
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Net Worth")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                Text(formatCurrency(netWorth, currency: currency))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(netWorth >= 0 ? Theme.Colors.income : Theme.Colors.expense)
                    .contentTransition(.numericText(value: netWorth))
                    .animation(.snappy, value: netWorth)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text(formatCurrency(viewModel.totalBalance, currency: currency))
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .label))
                    Text("assets")
                        .font(.system(size: 11))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                if viewModel.totalOutstandingOwed > 0 {
                    HStack(spacing: 4) {
                        Text("− \(formatCurrency(viewModel.totalOutstandingOwed, currency: currency))")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.expense)
                        Text("debts")
                            .font(.system(size: 11))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var healthChartSection: some View {
        HealthComponentsChart(scoreHistory: scoreHistory, color: healthColor)
            .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var healthBreakdownSection: some View {
        let goalsDesc = viewModel.goals.isEmpty ? "No goals set" : "\(viewModel.goals.count) goals, \(viewModel.goals.filter { $0.progress > 0 }.count) in progress"
        
        VStack(alignment: .leading, spacing: 14) {
            Text("Score Breakdown").font(.system(size: 15, weight: .semibold))
            HealthScoreRow(icon: "percent", title: "Savings Rate", description: "Saving \(Int(max(0, viewModel.savingsRate)))% of income", score: savingsRateScore, maxScore: 30, color: Theme.Colors.income)
            HealthScoreRow(icon: "gauge.with.dots.needle.33percent", title: "Budget Adherence", description: budgetAdherenceDescription, score: budgetAdherenceScore, maxScore: 15, color: Theme.Colors.primary)
            HealthScoreRow(icon: "target", title: "Goals Progress", description: goalsDesc, score: goalsScore, maxScore: 15, color: Theme.Colors.goals)
            HealthScoreRow(icon: "list.clipboard.fill", title: "Tracking Consistency", description: "\(viewModel.transactions.count) transactions recorded", score: trackingScore, maxScore: 15, color: Color(hex: "AF52DE"))
            HealthScoreRow(icon: "building.columns.fill", title: "Account Diversification", description: "\(viewModel.accounts.count) accounts", score: diversificationScore, maxScore: 10, color: Theme.Colors.transfer)
            HealthScoreRow(icon: "chart.line.downtrend.xyaxis", title: "Spending Trend", description: spendingTrendDescription, score: spendingTrendScore, maxScore: 15, color: Theme.Colors.recurring)
            HealthScoreRow(icon: "creditcard.fill", title: "Debt Burden", description: debtBurdenDescription, score: debtBurdenScore, maxScore: 15, color: Theme.Colors.expense)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var healthAllocationSection: some View {
        let totalMoney = viewModel.totalBalance
        let accountsTotal = viewModel.accounts.reduce(0) { $0 + viewModel.balanceForAccount($1) }
        let potsTotal = viewModel.totalEnvelopeBalance
        let currency = viewModel.appState.selectedCurrency
        
        VStack(alignment: .leading, spacing: 14) {
            Text("Money Allocation").font(.system(size: 15, weight: .semibold))
            
            if totalMoney > 0 {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        if accountsTotal > 0 {
                            RoundedRectangle(cornerRadius: 4).fill(Theme.Colors.primary)
                                .frame(width: geo.size.width * CGFloat(accountsTotal / totalMoney))
                        }
                        if potsTotal > 0 {
                            RoundedRectangle(cornerRadius: 4).fill(Theme.Colors.income)
                                .frame(width: geo.size.width * CGFloat(potsTotal / totalMoney))
                        }
                    }
                }
                .frame(height: 12)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle().fill(Theme.Colors.primary).frame(width: 8, height: 8)
                        Text("Accounts \(formatCurrency(accountsTotal, currency: currency))").font(.system(size: 11)).foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Theme.Colors.income).frame(width: 8, height: 8)
                        Text("Pots \(formatCurrency(potsTotal, currency: currency))").font(.system(size: 11)).foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
            } else {
                Text("No money tracked yet").font(.system(size: 13)).foregroundColor(Color(uiColor: .tertiaryLabel)).frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var healthTipsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How to Improve").font(.system(size: 15, weight: .semibold))
            
            if savingsRateScore < 30 {
                ImprovementTip(icon: "arrow.up.right.circle.fill", title: "Increase Savings", description: "Aim for 20%+ savings rate. You're at \(Int(max(0, viewModel.savingsRate)))%.", color: Theme.Colors.income, action: "Set a budget")
            }
            if budgetAdherenceScore < 15 {
                let hasBudgets = viewModel.categories.contains { ($0.budget ?? 0) > 0 }
                if !hasBudgets {
                    ImprovementTip(icon: "gauge.with.dots.needle.33percent", title: "Set Budgets", description: "Add monthly budgets to expense categories to track limits.", color: Theme.Colors.primary, action: "Go to Wallet")
                } else {
                    ImprovementTip(icon: "gauge.with.dots.needle.33percent", title: "Stay on Budget", description: "Some categories are over budget. Review your spending.", color: Theme.Colors.primary, action: "Review budgets")
                }
            }
            if goalsScore < 15 {
                let desc = viewModel.goals.isEmpty ? "Create savings goals to stay motivated." : "Start contributing to your goals."
                ImprovementTip(icon: "target", title: viewModel.goals.isEmpty ? "Set Goals" : "Progress Goals", description: desc, color: Theme.Colors.goals, action: "Create goal")
            }
            if trackingScore < 15 {
                ImprovementTip(icon: "plus.circle.fill", title: "Track More", description: "Record all transactions for better insights.", color: Color(hex: "AF52DE"), action: "Add transaction")
            }
            if diversificationScore < 10 {
                ImprovementTip(icon: "building.columns.fill", title: "Diversify Accounts", description: "Having 3+ accounts improves financial health.", color: Theme.Colors.transfer, action: "Add account")
            }
            if healthScore >= 80 {
                HStack(spacing: 10) {
                    Image(systemName: "star.fill").foregroundColor(Theme.Colors.goals)
                    Text("Outstanding! Your financial health is excellent.").font(.system(size: 14)).foregroundColor(Color(uiColor: .secondaryLabel))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.goals.opacity(0.08))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
    
    private var budgetAdherenceDescription: String {
        let budgeted = viewModel.categories.filter { ($0.budget ?? 0) > 0 }
        if budgeted.isEmpty { return "No budgets set" }
        let onBudget = budgeted.filter { viewModel.spendingForCategory($0) <= ($0.budget ?? 0) }
        return "\(onBudget.count)/\(budgeted.count) categories on budget"
    }
    
    private var spendingTrendDescription: String {
        let pct = viewModel.expenseDeltaPercent * 100
        if abs(pct) < 1 { return "Spending is stable" }
        if pct < 0 { return "Spending decreased \(Int(abs(pct)))% vs last period" }
        return "Spending increased \(Int(pct))% vs last period"
    }

    private var debtBurdenDescription: String {
        if viewModel.activeDebts.isEmpty { return "No active debts" }
        let overdueCount = viewModel.overdueDebts.count
        if overdueCount > 0 { return "\(overdueCount) overdue debt\(overdueCount == 1 ? "" : "s")" }
        return "\(viewModel.activeDebts.count) active, manageable debt\(viewModel.activeDebts.count == 1 ? "" : "s")"
    }
}

struct HealthComponentsChart: View {
    let scoreHistory: [(label: String, score: Int)]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Score Components")
                .font(.system(size: 15, weight: .semibold))
            
            Chart {
                ForEach(scoreHistory, id: \.label) { item in
                    BarMark(
                        x: .value("Score", item.score),
                        y: .value("Category", item.label)
                    )
                    .foregroundStyle(color.gradient)
                    .cornerRadius(4)
                }
            }
            .chartXScale(domain: 0...30)
            .frame(height: 180)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct HealthScoreRow: View {
    let icon: String
    let title: String
    let description: String
    let score: Int
    let maxScore: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
            
            Spacer()
            
            Text("\(score)/\(maxScore)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(score == maxScore ? color : Color(uiColor: .secondaryLabel))
        }
        .padding(.vertical, 4)
    }
}

struct ImprovementTip: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                Text(action)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(color.opacity(0.04))
        .cornerRadius(12)
    }
}

struct HealthTip: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
    }
}

// MARK: - Tips View
struct TipsView: View {
    @State private var expandedSection: String? = "Budgeting Tips"
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                FeaturedTipCard()
                    .padding(.horizontal, 16)
                
                TipCategoryCard(
                    title: "Budgeting Basics",
                    icon: "chart.pie.fill",
                    color: Theme.Colors.primary,
                    tips: [
                        ("dollarsign.circle.fill", "50/30/20 Rule", "Allocate 50% for needs, 30% for wants, and 20% for savings"),
                        ("list.clipboard.fill", "Track Everything", "Record all expenses, no matter how small"),
                        ("calendar", "Review Weekly", "Check your spending patterns every week"),
                        ("slider.horizontal.3", "Set Limits", "Create spending limits for each category")
                    ],
                    isExpanded: expandedSection == "Budgeting Tips",
                    onToggle: { expandedSection = expandedSection == "Budgeting Tips" ? nil : "Budgeting Tips" }
                )
                
                TipCategoryCard(
                    title: "Saving Strategies",
                    icon: "banknote.fill",
                    color: Theme.Colors.income,
                    tips: [
                        ("arrow.up.right.circle.fill", "Pay Yourself First", "Set aside savings before spending on anything else"),
                        ("clock.fill", "24-Hour Rule", "Before impulse purchases, wait a day to decide"),
                        ("building.columns.fill", "Emergency Fund", "Save 3-6 months of expenses for emergencies"),
                        ("arrow.triangle.2.circlepath", "Automate Savings", "Set up automatic transfers to savings accounts")
                    ],
                    isExpanded: expandedSection == "Saving",
                    onToggle: { expandedSection = expandedSection == "Saving" ? nil : "Saving" }
                )
                
                TipCategoryCard(
                    title: "Student Life",
                    icon: "graduationcap.fill",
                    color: Color(hex: "AF52DE"),
                    tips: [
                        ("percent", "Student Discounts", "Always ask for student discounts everywhere you go"),
                        ("book.fill", "Buy Used", "Consider used textbooks and second-hand items"),
                        ("fork.knife", "Cook at Home", "Meal prep to save money on food"),
                        ("bus.fill", "Public Transport", "Use student transit passes to save on travel"),
                        ("party.popper.fill", "Free Events", "Look for free campus events for entertainment")
                    ],
                    isExpanded: expandedSection == "Student",
                    onToggle: { expandedSection = expandedSection == "Student" ? nil : "Student" }
                )
                
                TipCategoryCard(
                    title: "Smart Spending",
                    icon: "cart.fill",
                    color: Theme.Colors.recurring,
                    tips: [
                        ("tag.fill", "Compare Prices", "Always compare prices before buying"),
                        ("star.fill", "Use Rewards", "Take advantage of cashback and rewards programs"),
                        ("square.and.arrow.down", "Unsubscribe", "Cancel unused subscriptions"),
                        ("arrow.clockwise", "Buy Quality", "Invest in quality items that last longer")
                    ],
                    isExpanded: expandedSection == "Spending",
                    onToggle: { expandedSection = expandedSection == "Spending" ? nil : "Spending" }
                )
            }
            .padding(.vertical, 14)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Tips & Guides")
    }
}

struct FeaturedTipCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.max.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.goals)
                Text("Featured Tip")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
            
            Text("The 50/30/20 Rule")
                .font(.system(size: 17, weight: .semibold))
            
            Text("A simple budgeting framework: allocate 50% of your income to needs, 30% to wants, and 20% to savings and debt repayment.")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .lineLimit(4)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Theme.Colors.goals.opacity(0.12), Theme.Colors.recurring.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

struct TipCategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let tips: [(String, String, String)]
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                onToggle()
                Haptics.light()
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(color)
                    }
                    
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .padding(16)
            }
            
            if isExpanded {
                Divider()
                
                VStack(spacing: 0) {
                    ForEach(0..<tips.count, id: \.self) { index in
                        let tip = tips[index]
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: tip.0)
                                .font(.system(size: 15))
                                .foregroundColor(color)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tip.1)
                                    .font(.system(size: 14, weight: .medium))
                                Text(tip.2)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(uiColor: .secondaryLabel))
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        
                        if index < tips.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding(.horizontal, 16)
        .animation(.snappy(duration: 0.3), value: isExpanded)
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @State private var spendingLimitText: String = ""
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        List {
            Section("Preferences") {
                NavigationLink(destination: CurrencySettingsView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Theme.Colors.income)
                            .frame(width: 24)
                        Text("Currency")
                        Spacer()
                        Text(viewModel.appState.selectedCurrency)
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
                
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 24)
                    Toggle("Open on Record tab", isOn: Binding(
                        get: { viewModel.appState.defaultTab == 2 },
                        set: { newValue in
                            viewModel.appState.defaultTab = newValue ? 2 : 0
                            viewModel.saveData()
                        }
                    ))
                    .font(.system(size: 15))
                }
            }
            
            Section(header: Text("Spending Limit"), footer: Text("Set your weekly spending limit. This powers the spending gauge on Home.")) {
                HStack {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 24)
                    Text("Weekly Limit")
                    Spacer()
                    TextField("0", text: $spendingLimitText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 15))
                        .frame(width: 100)
                        .onChange(of: spendingLimitText) { _, newValue in
                            if let value = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                                viewModel.appState.weeklySpendingLimit = value
                                viewModel.saveData()
                            }
                        }
                }
            }
            
            Section(header: Text("Notifications"), footer: Text("Control which notifications Balanced sends you.")) {
                HStack {
                    Image(systemName: "repeat.circle.fill")
                        .foregroundColor(Theme.Colors.recurring)
                        .frame(width: 24)
                    Toggle("Recurring reminders", isOn: Binding(
                        get: { viewModel.appState.recurringReminders },
                        set: { viewModel.appState.recurringReminders = $0; viewModel.saveData() }
                    ))
                    .font(.system(size: 15))
                }
                
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(Theme.Colors.goals)
                        .frame(width: 24)
                    Toggle("Goal deadline reminders", isOn: Binding(
                        get: { viewModel.appState.goalReminders },
                        set: { viewModel.appState.goalReminders = $0; viewModel.saveData() }
                    ))
                    .font(.system(size: 15))
                }
                
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 24)
                    Toggle("Weekly spending summary", isOn: Binding(
                        get: { viewModel.appState.weeklySummary },
                        set: { viewModel.appState.weeklySummary = $0; viewModel.saveData() }
                    ))
                    .font(.system(size: 15))
                }
            }
            
            Section("Data") {
                Button(action: exportCSV) {
                    HStack {
                        Image(systemName: "tablecells")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        Text("Export as CSV")
                            .foregroundColor(Color(uiColor: .label))
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
                
                Button(action: exportJSON) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        Text("Export as JSON")
                            .foregroundColor(Color(uiColor: .label))
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            spendingLimitText = viewModel.appState.weeklySpendingLimit > 0 ? String(format: "%.0f", viewModel.appState.weeklySpendingLimit) : ""
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func exportCSV() {
        var csv = "Date,Type,Amount,Account,Category,Title,Note\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for tx in viewModel.transactions.sorted(by: { $0.date > $1.date }) {
            let date = dateFormatter.string(from: tx.date)
            let type = tx.type.rawValue
            let amount = String(format: "%.2f", tx.amount)
            let account = viewModel.getAccount(by: tx.accountId)?.name ?? ""
            let category = viewModel.getCategory(by: tx.categoryId)?.name ?? ""
            let title = tx.title.replacingOccurrences(of: ",", with: ";")
            let note = tx.note.replacingOccurrences(of: ",", with: ";")
            csv += "\(date),\(type),\(amount),\(account),\(category),\(title),\(note)\n"
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Balanced_Export.csv")
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        exportURL = tempURL
        showExportSheet = true
    }
    
    private func exportJSON() {
        struct BalancedExport: Codable {
            let accounts: [Account]
            let categories: [Category]
            let transactions: [Transaction]
            let goals: [Goal]
            let recurringTransactions: [RecurringTransaction]
            let exportDate: Date
        }
        
        let export = BalancedExport(
            accounts: viewModel.accounts,
            categories: viewModel.categories,
            transactions: viewModel.transactions,
            goals: viewModel.goals,
            recurringTransactions: viewModel.recurringTransactions,
            exportDate: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(export) else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Balanced_Export.json")
        try? data.write(to: tempURL)
        exportURL = tempURL
        showExportSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct CurrencySettingsView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredCurrencies: [Currency] {
        if searchText.isEmpty { return Currency.allCurrencies }
        return Currency.allCurrencies.filter {
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                TextField("Search currency", text: $searchText)
                    .font(.system(size: 15))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
            .padding(10)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(10)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            
            ForEach(filteredCurrencies) { currency in
                Button(action: {
                    viewModel.appState.selectedCurrency = currency.code
                    viewModel.saveData()
                    Haptics.selection()
                    dismiss()
                }) {
                    HStack(spacing: 10) {
                        Text(currency.flag)
                        Text(currency.code)
                            .font(.system(size: 15, weight: .semibold))
                        Text(currency.name)
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        Spacer()
                        if viewModel.appState.selectedCurrency == currency.code {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
                .foregroundColor(Color(uiColor: .label))
            }
        }
        .navigationTitle("Currency")
    }
}

// MARK: - Help View
struct HelpView: View {
    var body: some View {
        List {
            Section("Contact") {
                Link(destination: URL(string: "mailto:support@balance.app")!) {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        Text("Email Support")
                            .foregroundColor(Color(uiColor: .label))
                    }
                }
            }
            
            Section("FAQ") {
                FAQItem(question: "How do I add a transaction?", answer: "Go to the Record tab and enter the amount, select type, choose an account and category, then tap Record.")
                
                FAQItem(question: "How do I set a spending limit?", answer: "Go to More > Settings > Weekly Limit. This controls the spending gauge on Home.")
                
                FAQItem(question: "What are Savings Pots?", answer: "Savings Pots let you allocate money for specific purposes like savings, investments, or charity.")
                
                FAQItem(question: "How do recurring transactions work?", answer: "Set up recurring expenses or income in More > Recurring. The app will remind you when they're due.")
            }
        }
        .navigationTitle("Help & Support")
    }
}

private struct FAQItem: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question)
                .font(.system(size: 15, weight: .medium))
            Text(answer)
                .font(.system(size: 13))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - About View
struct AboutBalancedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "scale.3d")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.primary)
            
            Text("Balanced")
                .font(.system(size: 28, weight: .bold))
            
            Text("Version 3.0")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            
            Text("Your personal finance companion")
                .font(.system(size: 15))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Text("Made to Change")
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .padding(.bottom, 1)
            Text("by Choche Sanchez")
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .padding(.bottom, 24)
        }
        .navigationTitle("About")
    }
}

#Preview {
    NavigationStack {
        MoreView(viewModel: BalancedViewModel())
    }
}
