import SwiftUI
import PhotosUI

// MARK: - More View
struct MoreView: View {
    @ObservedObject var viewModel: BalanceViewModel
    
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
                NavigationLink(destination: RecurringView(viewModel: viewModel)) {
                    RecurringBadgeRow(viewModel: viewModel)
                }
                
                NavigationLink(destination: AnalyticsView(viewModel: viewModel)) {
                    MoreRowView(icon: "chart.bar.fill", title: "Analytics", color: Theme.Colors.primary)
                }
                
                NavigationLink(destination: GoalsListView(viewModel: viewModel)) {
                    MoreRowView(icon: "target", title: "Goals", color: Theme.Colors.goals)
                }
                
                NavigationLink(destination: FinancialHealthView(viewModel: viewModel)) {
                    MoreRowView(icon: "heart.fill", title: "Financial Health", color: Theme.Colors.expense)
                }
                
                NavigationLink(destination: TipsView()) {
                    MoreRowView(icon: "lightbulb.max.fill", title: "Tips & Guides", color: Color(hex: "FFCC00"))
                }
            }
            
            // Settings
            Section("Settings") {
                NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                    MoreRowView(icon: "gearshape.fill", title: "Settings", color: Color(uiColor: .systemGray))
                }
            }
            
            // About
            Section("About") {
                NavigationLink(destination: HelpView()) {
                    MoreRowView(icon: "questionmark.circle.fill", title: "Help & Support", color: Theme.Colors.income)
                }
                
                NavigationLink(destination: AboutBalanceView()) {
                    MoreRowView(icon: "info.circle.fill", title: "About Balance", color: Theme.Colors.primary)
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
    @ObservedObject var viewModel: BalanceViewModel
    
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
    @ObservedObject var viewModel: BalanceViewModel
    @State private var selectedTimeRange: TimeRange = .monthly
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                TimeScopeSelector(selected: $selectedTimeRange, showAllOptions: true)
                    .padding(.horizontal, 16)
                
                // Overview
                VStack(alignment: .leading, spacing: 14) {
                    Text("\(selectedTimeRange.shortTitle) Overview")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(uiColor: .label))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
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
                            color: viewModel.savingsRate >= 20 ? Theme.Colors.income : Theme.Colors.recurring
                        )
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // Daily Averages
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Averages")
                        .font(.system(size: 15, weight: .semibold))
                    
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
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(14)
                .padding(.horizontal, 16)
                
                // Spending by Category
                if !viewModel.spendingByCategory().isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Spending by Category")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Text("\(viewModel.spendingByCategory().count) categories")
                                .font(.system(size: 12))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
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
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                }
                
                // Transaction Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transaction Activity")
                        .font(.system(size: 15, weight: .semibold))
                    
                    HStack(spacing: 16) {
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
                            color: Theme.Colors.transfer
                        )
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(14)
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Analytics")
    }
}

struct AnalyticsStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
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
    @ObservedObject var viewModel: BalanceViewModel
    @State private var showingAddGoal = false
    @State private var showingCalendar = false
    
    private var savingsPots: [Goal] { viewModel.goals.filter { $0.goalType == .envelope } }
    private var activeGoals: [Goal] { viewModel.goals.filter { $0.goalType == .goal && $0.progress < 100 } }
    private var completedGoals: [Goal] { viewModel.goals.filter { $0.goalType == .goal && $0.progress >= 100 } }
    
    var body: some View {
        List {
            if !viewModel.goals.isEmpty {
                Section {
                    VStack(spacing: 14) {
                        HStack(spacing: 24) {
                            GoalSummaryItem(
                                value: "\(viewModel.goals.filter { $0.goalType == .goal }.count)",
                                label: "Goals",
                                color: Theme.Colors.goals
                            )
                            GoalSummaryItem(
                                value: "\(savingsPots.count)",
                                label: "Pots",
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
            
            if !savingsPots.isEmpty {
                Section("Savings Pots") {
                    ForEach(savingsPots) { pot in
                        NavigationLink(destination: GoalDetailView(viewModel: viewModel, goal: pot)) {
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
                                    Text("Savings Pot")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(uiColor: .secondaryLabel))
                                }
                                
                                Spacer()
                                
                                Text(formatCurrency(pot.currentAmount, currency: viewModel.appState.selectedCurrency))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(pot.colorValue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet { viewModel.deleteGoal(savingsPots[index]) }
                    }
                }
            }
            
            if !activeGoals.isEmpty {
                Section("Active Goals") {
                    ForEach(activeGoals) { goal in
                        NavigationLink(destination: GoalDetailView(viewModel: viewModel, goal: goal)) {
                            GoalRowView(goal: goal, status: viewModel.status(for: goal), currency: viewModel.appState.selectedCurrency)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet { viewModel.deleteGoal(activeGoals[index]) }
                    }
                }
            }
            
            if !completedGoals.isEmpty {
                Section("Completed") {
                    ForEach(completedGoals) { goal in
                        NavigationLink(destination: GoalDetailView(viewModel: viewModel, goal: goal)) {
                            GoalRowView(goal: goal, status: viewModel.status(for: goal), currency: viewModel.appState.selectedCurrency)
                        }
                    }
                }
            }
            
            if viewModel.goals.isEmpty {
                VStack(spacing: 14) {
                    Spacer().frame(height: 40)
                    
                    Image(systemName: "target")
                        .font(.system(size: 44))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                    
                    Text("No Goals Yet")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Text("Create savings goals or pots\nto manage your money")
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
        .sheet(isPresented: $showingAddGoal) { AddGoalView(viewModel: viewModel) }
        .sheet(isPresented: $showingCalendar) { GoalsCalendarView(viewModel: viewModel) }
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
                ZStack {
                    Circle()
                        .fill(goal.colorValue.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: goal.icon)
                        .font(.system(size: 16))
                        .foregroundColor(goal.colorValue)
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
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    let goal: Goal
    @State private var showContribute = false
    @State private var showEdit = false
    
    private var currentGoal: Goal {
        viewModel.goals.first(where: { $0.id == goal.id }) ?? goal
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(currentGoal.colorValue.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: currentGoal.icon)
                            .font(.system(size: 36))
                            .foregroundColor(currentGoal.colorValue)
                    }
                    
                    Text(currentGoal.title)
                        .font(.system(size: 22, weight: .bold))
                    
                    if currentGoal.targetAmount > 0 {
                        Text("\(Int(currentGoal.progress))% complete")
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    
                    // Quick contribute buttons
                    HStack(spacing: 12) {
                        Button(action: { showContribute = true }) {
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
                        
                        if currentGoal.currentAmount > 0 {
                            Button(action: { showContribute = true }) {
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
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
            
            Section("Progress") {
                HStack {
                    Text("Current Amount")
                    Spacer()
                    Text(formatCurrency(currentGoal.currentAmount, currency: viewModel.appState.selectedCurrency))
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
                        Text(formatCurrency(max(0, currentGoal.targetAmount - currentGoal.currentAmount), currency: viewModel.appState.selectedCurrency))
                            .foregroundColor(Color(uiColor: .label))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(uiColor: .tertiarySystemFill))
                                .frame(height: 8)
                            Capsule()
                                .fill(currentGoal.colorValue)
                                .frame(width: geometry.size.width * CGFloat(min(currentGoal.progress / 100, 1.0)), height: 8)
                                .animation(.spring, value: currentGoal.progress)
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
        .navigationTitle(currentGoal.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showContribute) {
            GoalContributeSheet(viewModel: viewModel, goal: currentGoal)
        }
        .sheet(isPresented: $showEdit) {
            EditGoalView(viewModel: viewModel, goal: currentGoal)
        }
        .onChange(of: viewModel.goals.map(\.id)) { _, newIds in
            if !newIds.contains(goal.id) { dismiss() }
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
    @ObservedObject var viewModel: BalanceViewModel
    let goal: Goal
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var isWithdraw = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(goal.colorValue.opacity(0.12))
                        .frame(width: 60, height: 60)
                    Image(systemName: goal.icon)
                        .font(.system(size: 26))
                        .foregroundColor(goal.colorValue)
                }
                
                Text(goal.title)
                    .font(.system(size: 17, weight: .semibold))
                
                Text(formatCurrency(goal.currentAmount, currency: viewModel.appState.selectedCurrency))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(goal.colorValue)
                
                // Toggle add/withdraw
                Picker("", selection: $isWithdraw) {
                    Text("Add").tag(false)
                    Text("Withdraw").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
                
                HStack(spacing: 4) {
                    Text("$")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label).opacity(amount.isEmpty ? 0.25 : 1))
                    
                    TextField("0", text: $amount)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(uiColor: .label))
                }
                .frame(maxWidth: 200)
                
                Spacer()
                
                Button(action: contribute) {
                    Text(isWithdraw ? "Withdraw" : "Add Money")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Double(amount) != nil && Double(amount)! > 0 ? goal.colorValue : goal.colorValue.opacity(0.3))
                        .cornerRadius(14)
                }
                .disabled(Double(amount) == nil || Double(amount)! <= 0)
                .padding(.horizontal, 20)
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
            .navigationTitle(isWithdraw ? "Withdraw" : "Add Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
    }
    
    private func contribute() {
        guard let value = Double(amount), value > 0 else { return }
        let adjustedAmount = isWithdraw ? -value : value
        viewModel.contributeToGoal(goal, amount: adjustedAmount)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Edit Goal View
struct EditGoalView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let goal: Goal
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var targetAmount: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var selectedIcon: String
    @State private var selectedColorIndex: Int
    
    private let goalIcons = ["star.fill", "target", "banknote.fill", "chart.line.uptrend.xyaxis", "heart.fill", "graduationcap.fill", "airplane", "house.fill", "gift.fill", "leaf.fill", "car.fill", "laptopcomputer"]
    
    init(viewModel: BalanceViewModel, goal: Goal) {
        self.viewModel = viewModel
        self.goal = goal
        _title = State(initialValue: goal.title)
        _targetAmount = State(initialValue: goal.targetAmount > 0 ? String(format: "%.0f", goal.targetAmount) : "")
        _hasDeadline = State(initialValue: goal.deadline != nil)
        _deadline = State(initialValue: goal.deadline ?? Date().addingTimeInterval(86400 * 30))
        _selectedIcon = State(initialValue: goal.icon)
        
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
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    
                    if goal.goalType == .goal {
                        HStack {
                            Text("$")
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                            TextField("Target Amount", text: $targetAmount)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                if goal.goalType == .goal {
                    Section("Deadline") {
                        Toggle("Set Deadline", isOn: $hasDeadline)
                        if hasDeadline {
                            DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                        }
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(goalIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(selectedIcon == icon ? .white : Color(uiColor: .label))
                                    .frame(width: 40, height: 40)
                                    .background(selectedIcon == icon ? Theme.Colors.categoryColors[selectedColorIndex] : Color(uiColor: .tertiarySystemFill))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(0..<min(12, Theme.Colors.categoryColors.count), id: \.self) { index in
                            ColorPickerItem(
                                color: Theme.Colors.categoryColors[index],
                                isSelected: selectedColorIndex == index,
                                action: { selectedColorIndex = index }
                            )
                        }
                    }
                }
            }
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
            if let amount = Double(targetAmount) { updated.targetAmount = amount }
            updated.deadline = hasDeadline ? deadline : nil
        }
        viewModel.updateGoal(updated)
        Haptics.success()
        dismiss()
    }
}

struct GoalsCalendarView: View {
    @ObservedObject var viewModel: BalanceViewModel
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
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var goalType: GoalType = .goal
    @State private var title = ""
    @State private var targetAmount = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400 * 30)
    @State private var selectedColorIndex = 0
    @State private var selectedIcon = "star.fill"
    
    private let potIcons = ["banknote.fill", "chart.line.uptrend.xyaxis", "heart.fill", "graduationcap.fill", "airplane", "house.fill", "gift.fill", "leaf.fill"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }
                
                Section(goalType == .goal ? "Goal Details" : "Pot Details") {
                    TextField(goalType == .goal ? "Goal Title" : "Pot Name (e.g., Savings)", text: $title)
                    
                    if goalType == .goal {
                        HStack {
                            Text(currencySymbol)
                            TextField("Target Amount", text: $targetAmount)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                if goalType == .goal {
                    Section("Deadline") {
                        Toggle("Set Deadline", isOn: $hasDeadline)
                        
                        if hasDeadline {
                            DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                        }
                    }
                }
                
                if goalType == .envelope {
                    Section("Icon") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                            ForEach(potIcons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(selectedIcon == icon ? .white : Color(uiColor: .label))
                                        .frame(width: 36, height: 36)
                                        .background(selectedIcon == icon ? Theme.Colors.categoryColors[selectedColorIndex] : Color(uiColor: .tertiarySystemFill))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
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
            .navigationTitle(goalType == .goal ? "New Goal" : "New Savings Pot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addGoal() }
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty || (goalType == .goal && targetAmount.isEmpty))
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
        let colorHex = Theme.Colors.categoryColors[selectedColorIndex].toHex() ?? "#007AFF"
        
        if goalType == .envelope {
            let pot = Goal(title: title, icon: selectedIcon, color: colorHex, goalType: .envelope)
            viewModel.addGoal(pot)
        } else {
            guard let amount = Double(targetAmount) else { return }
            let goal = Goal(title: title, targetAmount: amount, deadline: hasDeadline ? deadline : nil, color: colorHex, goalType: .goal)
            viewModel.addGoal(goal)
        }
        
        Haptics.success()
        dismiss()
    }
}

// MARK: - Financial Health View
struct FinancialHealthView: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    private var healthScore: Int {
        var score = 50
        if viewModel.savingsRate >= 20 { score += 30 }
        else if viewModel.savingsRate >= 10 { score += 20 }
        else if viewModel.savingsRate > 0 { score += 10 }
        if !viewModel.goals.isEmpty { score += 10 }
        if viewModel.transactions.count > 10 { score += 10 }
        return min(score, 100)
    }
    
    private var healthColor: Color {
        if healthScore >= 80 { return Theme.Colors.income }
        else if healthScore >= 60 { return Theme.Colors.goals }
        else if healthScore >= 40 { return Theme.Colors.recurring }
        else { return Theme.Colors.expense }
    }
    
    private var healthLabel: String {
        if healthScore >= 80 { return "Excellent" }
        else if healthScore >= 60 { return "Good" }
        else if healthScore >= 40 { return "Fair" }
        else { return "Needs Work" }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Score
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
                
                // Breakdown
                VStack(alignment: .leading, spacing: 14) {
                    Text("Score Breakdown")
                        .font(.system(size: 15, weight: .semibold))
                    
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
                        color: Theme.Colors.goals
                    )
                    
                    HealthScoreRow(
                        icon: "list.clipboard.fill",
                        title: "Tracking",
                        description: "\(viewModel.transactions.count) transactions",
                        score: viewModel.transactions.count > 10 ? 10 : 0,
                        maxScore: 10,
                        color: Theme.Colors.primary
                    )
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // Tips
                VStack(alignment: .leading, spacing: 14) {
                    Text("How to Improve")
                        .font(.system(size: 15, weight: .semibold))
                    
                    if viewModel.savingsRate < 20 {
                        ImprovementTip(icon: "arrow.up.right.circle.fill", title: "Increase Savings", description: "Try to save at least 20% of your income.", color: Theme.Colors.income, action: "Set a budget")
                    }
                    
                    if viewModel.goals.isEmpty {
                        ImprovementTip(icon: "target", title: "Set Goals", description: "Create savings goals to stay motivated.", color: Theme.Colors.goals, action: "Create goal")
                    }
                    
                    if viewModel.transactions.count < 10 {
                        ImprovementTip(icon: "plus.circle.fill", title: "Track Everything", description: "Record all transactions for better insights.", color: Theme.Colors.primary, action: "Add transaction")
                    }
                    
                    if healthScore >= 80 {
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Theme.Colors.goals)
                            Text("Great job! Keep up the good work!")
                                .font(.system(size: 14))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
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
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
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
    @ObservedObject var viewModel: BalanceViewModel
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
            
            Section(header: Text("Notifications"), footer: Text("Control which notifications Balance sends you.")) {
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
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Balance_Export.csv")
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        exportURL = tempURL
        showExportSheet = true
    }
    
    private func exportJSON() {
        struct BalanceExport: Codable {
            let accounts: [Account]
            let categories: [Category]
            let transactions: [Transaction]
            let goals: [Goal]
            let recurringTransactions: [RecurringTransaction]
            let exportDate: Date
        }
        
        let export = BalanceExport(
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
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Balance_Export.json")
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
    @ObservedObject var viewModel: BalanceViewModel
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
struct AboutBalanceView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "scale.3d")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.primary)
            
            Text("Balance")
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
        MoreView(viewModel: BalanceViewModel())
    }
}
