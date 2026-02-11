import SwiftUI
import PhotosUI

// MARK: - More View
/// Settings, profile, and additional features
struct MoreView: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    var body: some View {
        List {
            // Profile Section
            Section {
                NavigationLink(destination: NewProfileView(viewModel: viewModel)) {
                    HStack(spacing: Theme.Spacing.md) {
                        // Profile Image
                        ProfileAvatarView(imageData: viewModel.userProfile.profileImageData, size: 56)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.userProfile.name.isEmpty ? "Set up your profile" : viewModel.userProfile.name)
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            Text(viewModel.userProfile.username.isEmpty ? (viewModel.userProfile.email.isEmpty ? "Tap to add details" : viewModel.userProfile.email) : "@\(viewModel.userProfile.username)")
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }
            }
            
            // Features Section
            Section("Features") {
                NavigationLink(destination: RecurringView(viewModel: viewModel)) {
                    RecurringBadgeRow(viewModel: viewModel)
                }
                
                NavigationLink(destination: AnalyticsView(viewModel: viewModel)) {
                    MoreRowView(icon: "chart.bar.fill", title: "Analytics & Insights", color: .blue)
                }
                
                NavigationLink(destination: GoalsListView(viewModel: viewModel)) {
                    MoreRowView(icon: "target", title: "Goals", color: .orange)
                }
                
                NavigationLink(destination: FinancialHealthView(viewModel: viewModel)) {
                    MoreRowView(icon: "heart.fill", title: "Financial Health", color: .red)
                }
                
                NavigationLink(destination: TipsView()) {
                    MoreRowView(icon: "lightbulb.fill", title: "Tips & Guides", color: .yellow)
                }
            }
            
            // Settings Section
            Section("Settings") {
                NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                    MoreRowView(icon: "gearshape.fill", title: "Settings", color: .gray)
                }
            }
            
            // About Section
            Section("About") {
                NavigationLink(destination: HelpView()) {
                    MoreRowView(icon: "questionmark.circle.fill", title: "Help & Support", color: .green)
                }
                
                NavigationLink(destination: AboutBalanceView()) {
                    MoreRowView(icon: "info.circle.fill", title: "About Balance", color: .blue)
                }
            }
            
            // Debug Section (for development)
            #if DEBUG
            Section("Developer") {
                Button(action: {
                    viewModel.resetOnboarding()
                }) {
                    MoreRowView(icon: "arrow.counterclockwise", title: "Reset Onboarding", color: .purple)
                }
                
                Button(action: {
                    viewModel.resetAllData()
                }) {
                    MoreRowView(icon: "trash.fill", title: "Reset All Data", color: .red)
                }
            }
            #endif
        }
        .listStyle(.insetGrouped)
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Recurring Badge Row
struct RecurringBadgeRow: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    private var badgeCount: Int {
        viewModel.overdueRecurring.count + viewModel.upcomingRecurring.filter { $0.isDueToday }.count
    }
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "repeat.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text("Recurring")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.primaryText)
            
            Spacer()
            
            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.xs)
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
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.primaryText)
        }
    }
}

// MARK: - New Profile View (Connected with Home Profile)
struct NewProfileView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var isEditing = false
    @State private var editingProfile: UserProfile
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    init(viewModel: BalanceViewModel) {
        self.viewModel = viewModel
        self._editingProfile = State(initialValue: viewModel.userProfile)
    }
    
    var body: some View {
        List {
            // Profile Header
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 14) {
                        // Photo -- always tappable to change
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
                        
                        // Quick Stats
                        HStack(spacing: 28) {
                            ProfileStat(value: "\(viewModel.transactions.count)", label: "Transactions")
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
                            .foregroundColor(Color(hex: "FF9500"))
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
                    ProfileRow(icon: "envelope.fill", iconColor: Color(hex: "FF9500"), title: "Email", value: viewModel.userProfile.email.isEmpty ? "Not set" : viewModel.userProfile.email)
                    ProfileRow(icon: "phone.fill", iconColor: Theme.Colors.income, title: "Phone", value: viewModel.userProfile.phone.isEmpty ? "Not set" : viewModel.userProfile.phone)
                }
            }
            
            // Financial Goal
            if let goal = viewModel.userProfile.primaryGoal {
                Section("Financial Goal") {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: goal.icon)
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        }
                        Text(goal.rawValue)
                            .font(.system(size: 15))
                    }
                }
            }
            
            // App Stats
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
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 24)
                    Text("Savings rate")
                    Spacer()
                    Text(String(format: "%.0f%%", max(0, viewModel.savingsRate)))
                        .font(.system(size: 14))
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
                    withAnimation(.easeInOut(duration: 0.2)) { isEditing.toggle() }
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
        // Use first transaction date or today
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
        VStack(spacing: Theme.Spacing.xxs) {
            Text(value)
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.primaryText)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }
}

struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Theme.Colors.secondaryText)
            Spacer()
            Text(value)
                .foregroundColor(Theme.Colors.primaryText)
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

// MARK: - Analytics View (Improved)
struct AnalyticsView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var selectedTimeRange: TimeRange = .monthly
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Time Range Selector
                TimeScopeSelector(selected: $selectedTimeRange, showAllOptions: true)
                    .padding(.horizontal, Theme.Spacing.md)
                
                // Monthly Overview
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("\(selectedTimeRange.shortTitle) Overview")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
                        AnalyticsStatCard(
                            icon: "arrow.down.circle.fill",
                            title: "Income",
                            value: formatCurrency(viewModel.currentRangeIncome, currency: viewModel.appState.selectedCurrency),
                            color: Theme.Colors.income
                        )
                        
                        AnalyticsStatCard(
                            icon: "arrow.up.circle.fill",
                            title: "Expenses",
                            value: formatCurrency(viewModel.currentRangeExpenses, currency: viewModel.appState.selectedCurrency),
                            color: Theme.Colors.expense
                        )
                        
                        AnalyticsStatCard(
                            icon: "banknote.fill",
                            title: "Net Savings",
                            value: formatCurrency(viewModel.currentRangeNet, currency: viewModel.appState.selectedCurrency),
                            color: viewModel.currentRangeNet >= 0 ? Theme.Colors.income : Theme.Colors.expense
                        )
                        
                        AnalyticsStatCard(
                            icon: "percent",
                            title: "Savings Rate",
                            value: String(format: "%.0f%%", max(0, viewModel.savingsRate)),
                            color: viewModel.savingsRate >= 20 ? Theme.Colors.income : .orange
                        )
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.large)
                .padding(.horizontal, Theme.Spacing.md)
                
                // Daily Average
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Daily Averages")
                        .font(Theme.Typography.headline)
                    
                    HStack {
                        DailyAverageItem(
                            title: "Income",
                            value: formatCurrency(viewModel.currentRangeIncome / 30, currency: viewModel.appState.selectedCurrency),
                            color: Theme.Colors.income
                        )
                        
                        DailyAverageItem(
                            title: "Expenses",
                            value: formatCurrency(viewModel.currentRangeExpenses / 30, currency: viewModel.appState.selectedCurrency),
                            color: Theme.Colors.expense
                        )
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
                .padding(.horizontal, Theme.Spacing.md)
                
                // Spending by Category
                if !viewModel.spendingByCategory().isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        HStack {
                            Text("Spending by Category")
                                .font(Theme.Typography.headline)
                            Spacer()
                            Text("\(viewModel.spendingByCategory().count) categories")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        
                        ForEach(viewModel.spendingByCategory().prefix(8), id: \.category.id) { item in
                            CategorySpendingRow(
                                category: item.category,
                                amount: item.amount,
                                percentage: item.percentage,
                                currency: viewModel.appState.selectedCurrency
                            )
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                    .padding(.horizontal, Theme.Spacing.md)
                }
                
                // Transaction Count
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Transaction Activity")
                        .font(Theme.Typography.headline)
                    
                    HStack(spacing: Theme.Spacing.lg) {
                        TransactionCountItem(
                            count: viewModel.currentRangeTransactions.filter { $0.type == .income }.count,
                            label: "Income",
                            icon: "arrow.down.circle.fill",
                            color: Theme.Colors.income
                        )
                        
                        TransactionCountItem(
                            count: viewModel.currentRangeTransactions.filter { $0.type == .expense }.count,
                            label: "Expenses",
                            icon: "arrow.up.circle.fill",
                            color: Theme.Colors.expense
                        )
                        
                        TransactionCountItem(
                            count: viewModel.currentRangeTransactions.filter { $0.type == .transfer }.count,
                            label: "Transfers",
                            icon: "arrow.left.arrow.right.circle.fill",
                            color: .orange
                        )
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
                .padding(.horizontal, Theme.Spacing.md)
                
                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(.top, Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Analytics")
    }
}

struct AnalyticsStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.small)
    }
}

struct DailyAverageItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundColor(color)
            Text("per day")
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.tertiaryText)
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
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(category.colorValue.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(category.colorValue)
            }
            
            Text(category.name)
                .font(Theme.Typography.body)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(amount, currency: currency))
                    .font(Theme.Typography.subheadline)
                
                Text(String(format: "%.0f%%", percentage))
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
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
        VStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text("\(count)")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.primaryText)
            Text(label)
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

// MARK: - Goals List View (Improved with Calendar button)
struct GoalsListView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var showingAddGoal = false
    @State private var showingCalendar = false
    
    var body: some View {
        List {
            // Summary Card
            if !viewModel.goals.isEmpty {
                Section {
                    VStack(spacing: Theme.Spacing.md) {
                        HStack(spacing: Theme.Spacing.xl) {
                            GoalSummaryItem(
                                value: "\(viewModel.goals.count)",
                                label: "Total Goals",
                                color: .orange
                            )
                            GoalSummaryItem(
                                value: "\(viewModel.goals.filter { $0.progress >= 100 }.count)",
                                label: "Completed",
                                color: Theme.Colors.income
                            )
                            GoalSummaryItem(
                                value: "\(viewModel.goals.filter { $0.progress < 100 }.count)",
                                label: "In Progress",
                                color: Theme.Colors.primary
                            )
                        }
                        
                        // Calendar Button
                        Button(action: { showingCalendar = true }) {
                            HStack {
                                Image(systemName: "calendar")
                                Text("View Goals Calendar")
                            }
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.primary)
                            .padding(Theme.Spacing.sm)
                            .frame(maxWidth: .infinity)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .cornerRadius(Theme.CornerRadius.small)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            
            // Active Goals
            let activeGoals = viewModel.goals.filter { $0.progress < 100 }
            if !activeGoals.isEmpty {
                Section("Active Goals") {
                    ForEach(activeGoals) { goal in
                        NavigationLink(destination: GoalDetailView(viewModel: viewModel, goal: goal)) {
                            GoalRowView(
                                goal: goal,
                                status: viewModel.status(for: goal),
                                currency: viewModel.appState.selectedCurrency
                            )
                        }
                    }
                }
            }
            
            // Completed Goals
            let completedGoals = viewModel.goals.filter { $0.progress >= 100 }
            if !completedGoals.isEmpty {
                Section("Completed") {
                    ForEach(completedGoals) { goal in
                        NavigationLink(destination: GoalDetailView(viewModel: viewModel, goal: goal)) {
                            GoalRowView(
                                goal: goal,
                                status: viewModel.status(for: goal),
                                currency: viewModel.appState.selectedCurrency
                            )
                        }
                    }
                }
            }
            
            // Empty State
            if viewModel.goals.isEmpty {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Text("No Goals Yet")
                        .font(Theme.Typography.headline)
                    
                    Text("Create your first savings goal to start tracking your progress!")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showingAddGoal = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Goal")
                        }
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primary)
                    }
                    .padding(.top, Theme.Spacing.sm)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xxl)
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
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCalendar) {
            GoalsCalendarView(viewModel: viewModel)
        }
    }
}

struct GoalSummaryItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Text(value)
                .font(Theme.Typography.title2)
                .foregroundColor(color)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }
}

struct GoalRowView: View {
    let goal: Goal
    let status: GoalStatus
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill(goal.colorValue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: goal.icon)
                        .font(.system(size: 16))
                        .foregroundColor(goal.colorValue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(Theme.Typography.headline)
                    
                    HStack(spacing: Theme.Spacing.xxs) {
                        Image(systemName: status.icon)
                            .font(.system(size: 10))
                        Text(status.label)
                            .font(Theme.Typography.caption)
                    }
                    .foregroundColor(status.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(goal.progress))%")
                        .font(Theme.Typography.headline)
                        .foregroundColor(goal.colorValue)
                    
                    Text(formatCurrency(goal.currentAmount, currency: currency))
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Colors.secondaryBackground)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(goal.colorValue)
                        .frame(width: geometry.size.width * CGFloat(min(goal.progress / 100, 1.0)), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

struct GoalDetailView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let goal: Goal
    
    var body: some View {
        List {
            Section {
                VStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(goal.colorValue.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: goal.icon)
                            .font(.system(size: 36))
                            .foregroundColor(goal.colorValue)
                    }
                    
                    Text(goal.title)
                        .font(Theme.Typography.title2)
                    
                    Text("\(Int(goal.progress))% complete")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
            
            Section("Progress") {
                HStack {
                    Text("Current Amount")
                    Spacer()
                    Text(formatCurrency(goal.currentAmount, currency: viewModel.appState.selectedCurrency))
                        .foregroundColor(Theme.Colors.income)
                }
                
                HStack {
                    Text("Target Amount")
                    Spacer()
                    Text(formatCurrency(goal.targetAmount, currency: viewModel.appState.selectedCurrency))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                HStack {
                    Text("Remaining")
                    Spacer()
                    Text(formatCurrency(max(0, goal.targetAmount - goal.currentAmount), currency: viewModel.appState.selectedCurrency))
                        .foregroundColor(Theme.Colors.primaryText)
                }
            }
            
            if let deadline = goal.deadline {
                Section("Deadline") {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Theme.Colors.primary)
                        Text(formatDate(deadline))
                    }
                }
            }
        }
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

struct GoalsCalendarView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.goals.filter { $0.deadline != nil }.sorted { ($0.deadline ?? Date()) < ($1.deadline ?? Date()) }) { goal in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(goal.colorValue.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: goal.icon)
                                .font(.system(size: 14))
                                .foregroundColor(goal.colorValue)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(goal.title)
                                .font(Theme.Typography.headline)
                            if let deadline = goal.deadline {
                                Text("Deadline: \(formatDate(deadline))")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(Int(goal.progress))%")
                            .font(Theme.Typography.headline)
                            .foregroundColor(goal.colorValue)
                    }
                }
                
                if viewModel.goals.filter({ $0.deadline != nil }).isEmpty {
                    Text("No goals with deadlines set")
                        .foregroundColor(Theme.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Goals Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Add Goal View
struct AddGoalView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var targetAmount = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400 * 30)
    @State private var selectedColorIndex = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal Title", text: $title)
                    
                    HStack {
                        Text(currencySymbol)
                        TextField("Target Amount", text: $targetAmount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Deadline") {
                    Toggle("Set Deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Theme.Spacing.sm) {
                        ForEach(0..<Theme.Colors.categoryColors.count, id: \.self) { index in
                            ColorPickerItem(
                                color: Theme.Colors.categoryColors[index],
                                isSelected: selectedColorIndex == index,
                                action: { selectedColorIndex = index }
                            )
                        }
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addGoal() }
                        .disabled(title.isEmpty || targetAmount.isEmpty)
                }
            }
        }
    }
    
    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.appState.selectedCurrency
        return formatter.currencySymbol ?? "$"
    }
    
    private func addGoal() {
        guard let amount = Double(targetAmount) else { return }
        
        let colorHex = Theme.Colors.categoryColors[selectedColorIndex].toHex() ?? "#007AFF"
        
        let goal = Goal(
            title: title,
            targetAmount: amount,
            deadline: hasDeadline ? deadline : nil,
            color: colorHex
        )
        
        viewModel.addGoal(goal)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Financial Health View (Improved)
struct FinancialHealthView: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    private var healthScore: Int {
        var score = 50
        
        // Savings rate (30 points max)
        if viewModel.savingsRate >= 20 { score += 30 }
        else if viewModel.savingsRate >= 10 { score += 20 }
        else if viewModel.savingsRate > 0 { score += 10 }
        
        // Goals (10 points)
        if !viewModel.goals.isEmpty { score += 10 }
        
        // Tracking consistency (10 points)
        if viewModel.transactions.count > 10 { score += 10 }
        
        return min(score, 100)
    }
    
    private var healthColor: Color {
        if healthScore >= 80 { return Theme.Colors.income }
        else if healthScore >= 60 { return .yellow }
        else if healthScore >= 40 { return .orange }
        else { return Theme.Colors.expense }
    }
    
    private var healthLabel: String {
        if healthScore >= 80 { return "Excellent" }
        else if healthScore >= 60 { return "Good" }
        else if healthScore >= 40 { return "Fair" }
        else { return "Needs Work" }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Score Circle
                VStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .stroke(Theme.Colors.secondaryBackground, lineWidth: 16)
                            .frame(width: 180, height: 180)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(healthScore) / 100)
                            .stroke(healthColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.8), value: healthScore)
                        
                        VStack(spacing: Theme.Spacing.xxs) {
                            Text("\(healthScore)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(healthColor)
                            Text(healthLabel)
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    
                    Text("Your Financial Health Score")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
                .padding(.top, Theme.Spacing.lg)
                
                // Score Breakdown
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Score Breakdown")
                        .font(Theme.Typography.headline)
                    
                    HealthScoreRow(
                        icon: "percent",
                        title: "Savings Rate",
                        description: "Saving \(Int(max(0, viewModel.savingsRate)))% of income",
                        score: viewModel.savingsRate >= 20 ? 30 : (viewModel.savingsRate >= 10 ? 20 : (viewModel.savingsRate > 0 ? 10 : 0)),
                        maxScore: 30,
                        color: Theme.Colors.income
                    )
                    
                    HealthScoreRow(
                        icon: "target",
                        title: "Goals",
                        description: viewModel.goals.isEmpty ? "No goals set" : "\(viewModel.goals.count) goals active",
                        score: viewModel.goals.isEmpty ? 0 : 10,
                        maxScore: 10,
                        color: .orange
                    )
                    
                    HealthScoreRow(
                        icon: "list.bullet.clipboard.fill",
                        title: "Tracking Consistency",
                        description: "\(viewModel.transactions.count) transactions recorded",
                        score: viewModel.transactions.count > 10 ? 10 : 0,
                        maxScore: 10,
                        color: Theme.Colors.primary
                    )
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
                .padding(.horizontal, Theme.Spacing.md)
                
                // Tips
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("How to Improve")
                        .font(Theme.Typography.headline)
                    
                    if viewModel.savingsRate < 20 {
                        ImprovementTip(
                            icon: "arrow.up.right.circle.fill",
                            title: "Increase Savings",
                            description: "Try to save at least 20% of your income each month.",
                            color: Theme.Colors.income,
                            action: "Set a budget"
                        )
                    }
                    
                    if viewModel.goals.isEmpty {
                        ImprovementTip(
                            icon: "target",
                            title: "Set Goals",
                            description: "Create savings goals to stay motivated and track progress.",
                            color: .orange,
                            action: "Create goal"
                        )
                    }
                    
                    if viewModel.transactions.count < 10 {
                        ImprovementTip(
                            icon: "plus.circle.fill",
                            title: "Track Everything",
                            description: "Record all your transactions for better insights.",
                            color: Theme.Colors.primary,
                            action: "Add transaction"
                        )
                    }
                    
                    if healthScore >= 80 {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Great job! Keep up the good work!")
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        .padding(Theme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(Theme.CornerRadius.small)
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
                .padding(.horizontal, Theme.Spacing.md)
                
                Spacer(minLength: Theme.Spacing.xxl)
            }
        }
        .background(Theme.Colors.background)
        .navigationTitle("Financial Health")
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
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.subheadline)
                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            Text("\(score)/\(maxScore)")
                .font(Theme.Typography.headline)
                .foregroundColor(score == maxScore ? color : Theme.Colors.secondaryText)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

struct ImprovementTip: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.headline)
                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Text(action)
                    .font(Theme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                    .padding(.top, 2)
            }
        }
        .padding(Theme.Spacing.sm)
        .background(color.opacity(0.05))
        .cornerRadius(Theme.CornerRadius.small)
    }
}

struct HealthTip: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.headline)
                Text(description)
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
    }
}

// MARK: - Tips View (Improved with categories)
struct TipsView: View {
    @State private var expandedSection: String? = "Budgeting Tips"
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                // Featured Tip
                FeaturedTipCard()
                    .padding(.horizontal, Theme.Spacing.md)
                
                // Tip Categories
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
                    color: .purple,
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
                    color: .orange,
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
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Tips & Guides")
    }
}

struct FeaturedTipCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Text("Featured Tip")
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Text("The 50/30/20 Rule")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.primaryText)
            
            Text("A simple budgeting framework: allocate 50% of your income to needs (rent, groceries), 30% to wants (entertainment, dining out), and 20% to savings and debt repayment.")
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.secondaryText)
                .lineLimit(4)
        }
        .padding(Theme.Spacing.lg)
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.15), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(Theme.CornerRadius.large)
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
            // Header
            Button(action: {
                onToggle()
                Haptics.light()
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .foregroundColor(color)
                    }
                    
                    Text(title)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(Theme.Spacing.md)
            }
            
            // Tips
            if isExpanded {
                Divider()
                
                VStack(spacing: 0) {
                    ForEach(0..<tips.count, id: \.self) { index in
                        let tip = tips[index]
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Image(systemName: tip.0)
                                .font(.system(size: 16))
                                .foregroundColor(color)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tip.1)
                                    .font(Theme.Typography.subheadline)
                                    .fontWeight(.medium)
                                Text(tip.2)
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding(Theme.Spacing.md)
                        
                        if index < tips.count - 1 {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
            }
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
        .padding(.horizontal, Theme.Spacing.md)
        .animation(.spring(response: 0.3), value: isExpanded)
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.headline)
                Text(description)
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    var body: some View {
        List {
            Section("Preferences") {
                NavigationLink(destination: CurrencySettingsView(viewModel: viewModel)) {
                    HStack {
                        Text("Currency")
                        Spacer()
                        Text(viewModel.appState.selectedCurrency)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            
            Section("Data") {
                Button("Export Data") {
                    // TODO: Implement export
                }
                
                Button("Import Data") {
                    // TODO: Implement import
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct CurrencySettingsView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return Currency.allCurrencies
        }
        return Currency.allCurrencies.filter {
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            // Search Field
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.secondaryText)
                TextField("Search currency", text: $searchText)
                    .font(Theme.Typography.body)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            
            ForEach(filteredCurrencies) { currency in
                Button(action: {
                    viewModel.appState.selectedCurrency = currency.code
                    Haptics.selection()
                    dismiss()
                }) {
                    HStack {
                        Text(currency.flag)
                        Text(currency.code)
                            .font(Theme.Typography.headline)
                        Text(currency.name)
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)
                        Spacer()
                        if viewModel.appState.selectedCurrency == currency.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
                .foregroundColor(Theme.Colors.primaryText)
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
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Theme.Colors.primary)
                        Text("Email Support")
                    }
                }
            }
            
            Section("FAQ") {
                Text("How do I add a transaction?")
                    .font(Theme.Typography.headline)
                Text("Go to the Record tab and enter the amount, select the type (income/expense/transfer), choose an account and category, then tap Record.")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .navigationTitle("Help & Support")
    }
}

// MARK: - About View
struct AboutBalanceView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "scale.3d")
                .font(.system(size: 64))
                .foregroundColor(Theme.Colors.primary)
            
            Text("Balance")
                .font(Theme.Typography.title1)
            
            Text("Version 1.0")
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("Your personal finance companion\nfor students and young people")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Text("Made with ❤️ for Swift Student Challenge 2025")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.tertiaryText)
                .padding(.bottom, Theme.Spacing.xl)
        }
        .navigationTitle("About")
    }
}
