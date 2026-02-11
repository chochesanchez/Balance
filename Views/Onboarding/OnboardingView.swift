import SwiftUI
import PhotosUI

// MARK: - Reusable Input Field (Apple iOS filled style)
struct OnboardingTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var disableAutocorrection: Bool = false
    var isSecure: Bool = false
    var icon: String? = nil
    var centered: Bool = false
    var fontSize: CGFloat = 16
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 6) {
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .padding(.leading, centered ? 0 : 4)
            }
            
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isFocused ? Theme.Colors.primary : Color(uiColor: .tertiaryLabel))
                        .frame(width: 20)
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                }
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: fontSize))
                        .multilineTextAlignment(centered ? .center : .leading)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.system(size: fontSize))
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled(disableAutocorrection)
                        .multilineTextAlignment(centered ? .center : .leading)
                        .focused($isFocused)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(uiColor: .tertiarySystemFill))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Theme.Colors.primary.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
        }
    }
}

// MARK: - Primary CTA Button
struct OnboardingButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isEnabled ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.35))
                .cornerRadius(14)
        }
        .disabled(!isEnabled)
        .buttonStyle(PressEffectButtonStyle())
    }
}

// MARK: - Step Icon Badge
struct StepIconBadge: View {
    let icon: String
    var color: Color = Theme.Colors.primary
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 30))
            .foregroundColor(color)
            .padding(18)
            .background(color.opacity(0.1))
            .clipShape(Circle())
    }
}

// MARK: - Welcome Screen (Root)
struct AuthGateView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var appeared = false
    @State private var showOnboarding = false
    @State private var showLogin = false
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.08))
                            .frame(width: 130, height: 130)
                        
                        Image(systemName: "scale.3d")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundStyle(Theme.Colors.primary)
                    }
                    .scaleEffect(appeared ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)
                    
                    VStack(spacing: 6) {
                        Text("Welcome to")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        
                        Text("Balance")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(Color(uiColor: .label))
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    
                    Text("Your personal finance companion")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .opacity(appeared ? 1 : 0)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    OnboardingButton(title: "Get Started") {
                        showOnboarding = true
                    }
                    
                    Button(action: { showLogin = true }) {
                        Text("Already have an account? ")
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        +
                        Text("Log In")
                            .foregroundColor(Theme.Colors.primary)
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 14))
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView(viewModel: viewModel)
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?
    
    enum Field { case email, password }
    
    private var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
                .onTapGesture { focusedField = nil }
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .frame(height: 44)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        StepIconBadge(icon: "person.crop.circle.fill", color: Theme.Colors.primary)
                            .padding(.top, 24)
                            .padding(.bottom, 16)
                        
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color(uiColor: .label))
                            
                            Text("Sign in to your account")
                                .font(.system(size: 15))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                        .padding(.bottom, 36)
                        
                        VStack(spacing: 16) {
                            OnboardingTextField(
                                label: "Email",
                                placeholder: "your@email.com",
                                text: $email,
                                keyboardType: .emailAddress,
                                autocapitalization: .never,
                                disableAutocorrection: true,
                                icon: "envelope"
                            )
                            
                            OnboardingTextField(
                                label: "Password",
                                placeholder: "Enter your password",
                                text: $password,
                                isSecure: true,
                                icon: "lock"
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        HStack {
                            Spacer()
                            Button(action: {}) {
                                Text("Forgot password?")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 10)
                        
                        OnboardingButton(title: "Log In", isEnabled: canLogin) {
                            focusedField = nil
                            viewModel.completeOnboarding()
                            Haptics.success()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        Button(action: { dismiss() }) {
                            Text("Don't have an account? ")
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                            +
                            Text("Sign Up")
                                .foregroundColor(Theme.Colors.primary)
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                        .padding(.top, 20)
                    }
                }
            }
        }
    }
}

// MARK: - Onboarding Container
// Flow: Name -> Photo+Username -> Goals -> Habits -> Currencies -> Email+Phone -> Password -> Start
struct OnboardingView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    @State private var userName = ""
    @State private var username = ""
    @State private var profileImage: UIImage?
    @State private var selectedGoals: Set<FinancialGoal> = []
    @State private var selectedHabits: Set<SpendingHabit> = []
    @State private var selectedCurrencies: [Currency] = [.usd]
    @State private var defaultCurrency: Currency = .usd
    @State private var userEmail = ""
    @State private var userPhone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    private let totalPages = 9
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
                .onTapGesture { hideKeyboard() }
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        if currentPage > 0 { previousPage() } else { dismiss() }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .frame(height: 44)
                
                TabView(selection: $currentPage) {
                    NameStepScreen(name: $userName, onContinue: { hideKeyboard(); nextPage() })
                        .tag(0)
                    
                    ProfilePhotoScreen(profileImage: $profileImage, onContinue: nextPage)
                        .tag(1)
                    
                    GoalSelectionScreen(selectedGoals: $selectedGoals, onContinue: nextPage)
                        .tag(2)
                    
                    SpendingHabitsScreen(selectedHabits: $selectedHabits, onContinue: nextPage)
                        .tag(3)
                    
                    CurrencySelectionScreen(
                        selectedCurrencies: $selectedCurrencies,
                        defaultCurrency: $defaultCurrency,
                        onContinue: { hideKeyboard(); nextPage() }
                    )
                    .tag(4)
                    
                    AccountDetailsScreen(email: $userEmail, phone: $userPhone, onContinue: { hideKeyboard(); nextPage() })
                        .tag(5)
                    
                    CreatePasswordScreen(password: $password, confirmPassword: $confirmPassword, onContinue: { hideKeyboard(); nextPage() })
                        .tag(6)
                    
                    UsernameStepScreen(username: $username, onContinue: { hideKeyboard(); nextPage() })
                        .tag(7)
                    
                    ReadyToStartScreen(onStart: completeOnboarding)
                        .tag(8)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }
    
    private func nextPage() {
        hideKeyboard()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            if currentPage < totalPages - 1 { currentPage += 1 }
        }
        Haptics.selection()
    }
    
    private func previousPage() {
        hideKeyboard()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            if currentPage > 0 { currentPage -= 1 }
        }
        Haptics.selection()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func completeOnboarding() {
        var profile = viewModel.userProfile
        profile.name = userName
        profile.username = username
        profile.email = userEmail
        profile.phone = userPhone
        profile.primaryGoal = selectedGoals.first
        if let imageData = profileImage?.jpegData(compressionQuality: 0.8) {
            profile.profileImageData = imageData
        }
        viewModel.updateUserProfile(profile)
        viewModel.appState.selectedCurrency = defaultCurrency.code
        viewModel.completeOnboarding()
        Haptics.success()
    }
}

// MARK: - Step 1: Name
struct NameStepScreen: View {
    @Binding var name: String
    let onContinue: () -> Void
    @FocusState private var isFocused: Bool
    
    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                StepIconBadge(icon: "person.fill", color: Theme.Colors.primary)
                
                VStack(spacing: 6) {
                    Text("What's your name?")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text("Let's personalize your experience")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                
                TextField("Enter your full name", text: $name)
                    .font(.system(size: 20, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? Theme.Colors.primary.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
                    .padding(.horizontal, 24)
                    .focused($isFocused)
            }
            
            Spacer()
            
            OnboardingButton(title: "Continue", isEnabled: canContinue, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isFocused = true }
        }
    }
}

// MARK: - Step 2: Profile Photo
struct ProfilePhotoScreen: View {
    @Binding var profileImage: UIImage?
    let onContinue: () -> Void
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                StepIconBadge(icon: "camera.fill", color: Color(hex: "FF9500"))
                
                VStack(spacing: 6) {
                    Text("Set your profile photo")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text("Help your friends recognize you")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                
                Button(action: { showingImagePicker = true }) {
                    ZStack(alignment: .bottomTrailing) {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(uiColor: .tertiarySystemFill))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    VStack(spacing: 4) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 30))
                                        Text("Add Photo")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                                )
                        }
                        
                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: profileImage != nil ? "pencil" : "plus")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 4, y: 4)
                    }
                }
                .padding(.top, 8)
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                OnboardingButton(title: "Continue", action: onContinue)
                
                if profileImage == nil {
                    Button(action: onContinue) {
                        Text("Skip for now")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .sheet(isPresented: $showingImagePicker) {
            OnboardingImagePicker(image: $profileImage)
        }
    }
}

// MARK: - Step 3: Username
struct UsernameStepScreen: View {
    @Binding var username: String
    let onContinue: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                StepIconBadge(icon: "at", color: Color(hex: "5856D6"))
                
                VStack(spacing: 6) {
                    Text("Pick a username")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text("Your unique identity on Balance")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                
                HStack(spacing: 8) {
                    Text("@")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                    
                    TextField("username", text: $username)
                        .font(.system(size: 18))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(uiColor: .tertiarySystemFill))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Theme.Colors.primary.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            OnboardingButton(title: "Continue", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isFocused = true }
        }
    }
}

// MARK: - Step 4: Financial Goals
struct GoalSelectionScreen: View {
    @Binding var selectedGoals: Set<FinancialGoal>
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                StepIconBadge(icon: "target", color: Color(hex: "FF9500"))
                
                VStack(spacing: 6) {
                    Text("What are your")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Text("financial goals?")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text("Select all that apply")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                        .padding(.top, 2)
                }
                
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(FinancialGoal.allCases, id: \.self) { goal in
                        ColoredGoalButton(
                            goal: goal,
                            isSelected: selectedGoals.contains(goal),
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedGoals.contains(goal) {
                                        selectedGoals.remove(goal)
                                    } else {
                                        selectedGoals.insert(goal)
                                    }
                                }
                                Haptics.selection()
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Text("You can change this later in Settings")
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            
            Spacer()
            
            OnboardingButton(title: selectedGoals.isEmpty ? "Skip" : "Continue", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 5: Spending Habits
enum SpendingHabit: String, CaseIterable, Identifiable {
    case cashOnly = "Mostly cash"
    case cardPayments = "Card payments"
    case mobilePayments = "Mobile payments"
    case mixedMethods = "A mix of everything"
    case subscriptions = "Lots of subscriptions"
    case impulse = "Impulse buyer"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .cashOnly: return "banknote.fill"
        case .cardPayments: return "creditcard.fill"
        case .mobilePayments: return "iphone.gen3"
        case .mixedMethods: return "arrow.triangle.branch"
        case .subscriptions: return "repeat.circle.fill"
        case .impulse: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .cashOnly: return Color(hex: "34C759")
        case .cardPayments: return Color(hex: "007AFF")
        case .mobilePayments: return Color(hex: "5856D6")
        case .mixedMethods: return Color(hex: "FF9500")
        case .subscriptions: return Color(hex: "FF2D55")
        case .impulse: return Color(hex: "FFCC00")
        }
    }
}

struct SpendingHabitsScreen: View {
    @Binding var selectedHabits: Set<SpendingHabit>
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                StepIconBadge(icon: "cart.fill", color: Color(hex: "FF2D55"))
                
                VStack(spacing: 6) {
                    Text("How do you")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    Text("usually spend?")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text("Select all that apply")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                        .padding(.top, 2)
                }
                
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(SpendingHabit.allCases) { habit in
                        SpendingHabitButton(
                            habit: habit,
                            isSelected: selectedHabits.contains(habit),
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedHabits.contains(habit) {
                                        selectedHabits.remove(habit)
                                    } else {
                                        selectedHabits.insert(habit)
                                    }
                                }
                                Haptics.selection()
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Text("This helps us tailor your experience")
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            
            Spacer()
            
            OnboardingButton(title: selectedHabits.isEmpty ? "Skip" : "Continue", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
        }
    }
}

struct SpendingHabitButton: View {
    let habit: SpendingHabit
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(habit.color.opacity(isSelected ? 0.2 : 0.08))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: habit.icon)
                        .font(.system(size: 20))
                        .foregroundColor(habit.color)
                        .symbolEffect(.bounce.byLayer, value: isSelected)
                }
                
                Text(habit.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(uiColor: .label))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(isSelected ? habit.color.opacity(0.06) : Color(uiColor: .tertiarySystemFill))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? habit.color.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Step 6: Currency Selection
struct CurrencySelectionScreen: View {
    @Binding var selectedCurrencies: [Currency]
    @Binding var defaultCurrency: Currency
    let onContinue: () -> Void
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    
    private var filteredCurrencies: [Currency] {
        if searchText.isEmpty { return Currency.allCurrencies }
        return Currency.allCurrencies.filter {
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                StepIconBadge(icon: "dollarsign.circle.fill", color: Theme.Colors.income)
                
                Text("Choose your currencies")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Color(uiColor: .label))
                
                Text("Select one or more currencies you use")
                    .font(.system(size: 15))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
            .padding(.top, 12)
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                
                TextField("Search (USD, MXN, EUR...)", text: $searchText)
                    .font(.system(size: 16))
                    .focused($searchFocused)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color(uiColor: .tertiarySystemFill))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            
            if !selectedCurrencies.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedCurrencies, id: \.code) { currency in
                            SelectedCurrencyChip(
                                currency: currency,
                                isDefault: currency.code == defaultCurrency.code,
                                onRemove: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCurrencies.removeAll { $0.code == currency.code }
                                        if defaultCurrency.code == currency.code && !selectedCurrencies.isEmpty {
                                            defaultCurrency = selectedCurrencies[0]
                                        }
                                    }
                                },
                                onSetDefault: { defaultCurrency = currency }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 36)
            }
            
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filteredCurrencies, id: \.code) { currency in
                        MultiCurrencyRow(
                            currency: currency,
                            isSelected: selectedCurrencies.contains { $0.code == currency.code },
                            isDefault: defaultCurrency.code == currency.code,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    if selectedCurrencies.contains(where: { $0.code == currency.code }) {
                                        if selectedCurrencies.count > 1 {
                                            selectedCurrencies.removeAll { $0.code == currency.code }
                                            if defaultCurrency.code == currency.code {
                                                defaultCurrency = selectedCurrencies[0]
                                            }
                                        }
                                    } else {
                                        selectedCurrencies.append(currency)
                                        if selectedCurrencies.count == 1 { defaultCurrency = currency }
                                    }
                                }
                                Haptics.selection()
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            
            OnboardingButton(title: "Continue", isEnabled: !selectedCurrencies.isEmpty, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }
}

struct SelectedCurrencyChip: View {
    let currency: Currency
    let isDefault: Bool
    let onRemove: () -> Void
    let onSetDefault: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(currency.flag)
                .font(.system(size: 14))
            Text(currency.code)
                .font(.system(size: 12, weight: .semibold))
            
            if isDefault {
                Text("Default")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Theme.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            } else {
                Button(action: onSetDefault) {
                    Image(systemName: "star")
                        .font(.system(size: 9))
                }
            }
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .foregroundColor(Color(uiColor: .label))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.Colors.primary.opacity(0.08))
        .cornerRadius(20)
    }
}

struct MultiCurrencyRow: View {
    let currency: Currency
    let isSelected: Bool
    let isDefault: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(currency.flag)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(currency.code)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(uiColor: .label))
                        
                        if isDefault {
                            Text("Default")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    Text(currency.name)
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                
                Spacer()
                
                Text(currency.symbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Theme.Colors.primary : Color(uiColor: .quaternaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.Colors.primary.opacity(0.05) : Color(uiColor: .tertiarySystemFill))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.Colors.primary.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

struct ColoredGoalButton: View {
    let goal: FinancialGoal
    let isSelected: Bool
    let action: () -> Void
    
    var goalColor: Color {
        switch goal {
        case .saveMore: return Color(hex: "34C759")
        case .trackSpending: return Color(hex: "007AFF")
        case .reachGoal: return Color(hex: "FF9500")
        case .buildHabits: return Color(hex: "AF52DE")
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(goalColor.opacity(isSelected ? 0.2 : 0.08))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: goal.icon)
                        .font(.system(size: 20))
                        .foregroundColor(goalColor)
                        .symbolEffect(.bounce.byLayer, value: isSelected)
                }
                
                Text(goal.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(uiColor: .label))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(isSelected ? goalColor.opacity(0.06) : Color(uiColor: .tertiarySystemFill))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? goalColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Step 7: Account Details (Email + Phone)
struct AccountDetailsScreen: View {
    @Binding var email: String
    @Binding var phone: String
    let onContinue: () -> Void
    @FocusState private var focusedField: Field?
    
    enum Field { case email, phone }
    
    private var canContinue: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                StepIconBadge(icon: "envelope.fill", color: Color(hex: "5856D6"))
                
                VStack(spacing: 6) {
                    Text("Account details")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text("For account recovery")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                
                VStack(spacing: 14) {
                    OnboardingTextField(
                        label: "Email",
                        placeholder: "your@email.com",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        disableAutocorrection: true,
                        icon: "envelope"
                    )
                    
                    OnboardingTextField(
                        label: "Phone",
                        placeholder: "+1 234 567 8900",
                        text: $phone,
                        keyboardType: .phonePad,
                        icon: "phone"
                    )
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            OnboardingButton(title: "Continue", isEnabled: canContinue, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 8: Create Password
struct CreatePasswordScreen: View {
    @Binding var password: String
    @Binding var confirmPassword: String
    let onContinue: () -> Void
    @FocusState private var focusedField: Field?
    
    enum Field { case password, confirm }
    
    private var canContinue: Bool {
        password.count >= 6 && password == confirmPassword
    }
    
    private var passwordMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                StepIconBadge(icon: "lock.fill", color: Color(hex: "34C759"))
                
                VStack(spacing: 6) {
                    Text("Create a password")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text("Secure your account")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                
                VStack(spacing: 14) {
                    OnboardingTextField(
                        label: "Password",
                        placeholder: "At least 6 characters",
                        text: $password,
                        isSecure: true,
                        icon: "lock"
                    )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        OnboardingTextField(
                            label: "Confirm Password",
                            placeholder: "Re-enter your password",
                            text: $confirmPassword,
                            isSecure: true,
                            icon: "lock.fill"
                        )
                        
                        if passwordMismatch {
                            Text("Passwords don't match")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(uiColor: .systemRed))
                                .padding(.leading, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: passwordMismatch)
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            OnboardingButton(title: "Continue", isEnabled: canContinue, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focusedField = .password }
        }
    }
}

// MARK: - Step 9: Ready to Start
struct ReadyToStartScreen: View {
    let onStart: () -> Void
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.income.opacity(0.06))
                        .frame(width: 130, height: 130)
                    
                    Circle()
                        .fill(Theme.Colors.income.opacity(0.1))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.Colors.income)
                        .symbolEffect(.bounce.up.byLayer, value: appeared)
                }
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                
                VStack(spacing: 8) {
                    Text("You're all set!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(uiColor: .label))
                    
                    Text("Let's take a quick tour of Balance\nand set up your first account")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    TourStepPreview(number: 1, title: "Add your first account", icon: "wallet.pass.fill")
                    TourStepPreview(number: 2, title: "Create categories", icon: "square.grid.2x2.fill")
                    TourStepPreview(number: 3, title: "Record your first transaction", icon: "plus.circle.fill")
                }
                .padding(18)
                .background(Color(uiColor: .tertiarySystemFill))
                .cornerRadius(16)
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            OnboardingButton(title: "Start", action: onStart)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }
}

struct TourStepPreview: View {
    let number: Int
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.1))
                    .frame(width: 34, height: 34)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Color(uiColor: .label))
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
    }
}

// MARK: - Currency Model
struct Currency: Identifiable, Equatable {
    let id = UUID()
    let code: String
    let name: String
    let symbol: String
    let flag: String
    
    static let usd = Currency(code: "USD", name: "US Dollar", symbol: "$", flag: "\u{1F1FA}\u{1F1F8}")
    static let mxn = Currency(code: "MXN", name: "Mexican Peso", symbol: "$", flag: "\u{1F1F2}\u{1F1FD}")
    static let eur = Currency(code: "EUR", name: "Euro", symbol: "\u{20AC}", flag: "\u{1F1EA}\u{1F1FA}")
    static let gbp = Currency(code: "GBP", name: "British Pound", symbol: "\u{00A3}", flag: "\u{1F1EC}\u{1F1E7}")
    
    static let allCurrencies: [Currency] = [
        Currency(code: "USD", name: "US Dollar", symbol: "$", flag: "\u{1F1FA}\u{1F1F8}"),
        Currency(code: "MXN", name: "Mexican Peso", symbol: "$", flag: "\u{1F1F2}\u{1F1FD}"),
        Currency(code: "EUR", name: "Euro", symbol: "\u{20AC}", flag: "\u{1F1EA}\u{1F1FA}"),
        Currency(code: "GBP", name: "British Pound", symbol: "\u{00A3}", flag: "\u{1F1EC}\u{1F1E7}"),
        Currency(code: "CAD", name: "Canadian Dollar", symbol: "$", flag: "\u{1F1E8}\u{1F1E6}"),
        Currency(code: "AUD", name: "Australian Dollar", symbol: "$", flag: "\u{1F1E6}\u{1F1FA}"),
        Currency(code: "JPY", name: "Japanese Yen", symbol: "\u{00A5}", flag: "\u{1F1EF}\u{1F1F5}"),
        Currency(code: "CNY", name: "Chinese Yuan", symbol: "\u{00A5}", flag: "\u{1F1E8}\u{1F1F3}"),
        Currency(code: "INR", name: "Indian Rupee", symbol: "\u{20B9}", flag: "\u{1F1EE}\u{1F1F3}"),
        Currency(code: "BRL", name: "Brazilian Real", symbol: "R$", flag: "\u{1F1E7}\u{1F1F7}"),
        Currency(code: "ARS", name: "Argentine Peso", symbol: "$", flag: "\u{1F1E6}\u{1F1F7}"),
        Currency(code: "COP", name: "Colombian Peso", symbol: "$", flag: "\u{1F1E8}\u{1F1F4}"),
        Currency(code: "CLP", name: "Chilean Peso", symbol: "$", flag: "\u{1F1E8}\u{1F1F1}"),
        Currency(code: "PEN", name: "Peruvian Sol", symbol: "S/", flag: "\u{1F1F5}\u{1F1EA}"),
        Currency(code: "KRW", name: "South Korean Won", symbol: "\u{20A9}", flag: "\u{1F1F0}\u{1F1F7}"),
        Currency(code: "SGD", name: "Singapore Dollar", symbol: "$", flag: "\u{1F1F8}\u{1F1EC}"),
        Currency(code: "HKD", name: "Hong Kong Dollar", symbol: "$", flag: "\u{1F1ED}\u{1F1F0}"),
        Currency(code: "TWD", name: "Taiwan Dollar", symbol: "NT$", flag: "\u{1F1F9}\u{1F1FC}"),
        Currency(code: "THB", name: "Thai Baht", symbol: "\u{0E3F}", flag: "\u{1F1F9}\u{1F1ED}"),
        Currency(code: "PHP", name: "Philippine Peso", symbol: "\u{20B1}", flag: "\u{1F1F5}\u{1F1ED}"),
        Currency(code: "IDR", name: "Indonesian Rupiah", symbol: "Rp", flag: "\u{1F1EE}\u{1F1E9}"),
        Currency(code: "MYR", name: "Malaysian Ringgit", symbol: "RM", flag: "\u{1F1F2}\u{1F1FE}"),
        Currency(code: "VND", name: "Vietnamese Dong", symbol: "\u{20AB}", flag: "\u{1F1FB}\u{1F1F3}"),
        Currency(code: "CHF", name: "Swiss Franc", symbol: "CHF", flag: "\u{1F1E8}\u{1F1ED}"),
        Currency(code: "SEK", name: "Swedish Krona", symbol: "kr", flag: "\u{1F1F8}\u{1F1EA}"),
        Currency(code: "NOK", name: "Norwegian Krone", symbol: "kr", flag: "\u{1F1F3}\u{1F1F4}"),
        Currency(code: "DKK", name: "Danish Krone", symbol: "kr", flag: "\u{1F1E9}\u{1F1F0}"),
        Currency(code: "PLN", name: "Polish Zloty", symbol: "z\u{0142}", flag: "\u{1F1F5}\u{1F1F1}"),
        Currency(code: "CZK", name: "Czech Koruna", symbol: "K\u{010D}", flag: "\u{1F1E8}\u{1F1FF}"),
        Currency(code: "HUF", name: "Hungarian Forint", symbol: "Ft", flag: "\u{1F1ED}\u{1F1FA}"),
        Currency(code: "RUB", name: "Russian Ruble", symbol: "\u{20BD}", flag: "\u{1F1F7}\u{1F1FA}"),
        Currency(code: "TRY", name: "Turkish Lira", symbol: "\u{20BA}", flag: "\u{1F1F9}\u{1F1F7}"),
        Currency(code: "ZAR", name: "South African Rand", symbol: "R", flag: "\u{1F1FF}\u{1F1E6}"),
        Currency(code: "AED", name: "UAE Dirham", symbol: "\u{062F}.\u{0625}", flag: "\u{1F1E6}\u{1F1EA}"),
        Currency(code: "SAR", name: "Saudi Riyal", symbol: "\u{FDFC}", flag: "\u{1F1F8}\u{1F1E6}"),
        Currency(code: "ILS", name: "Israeli Shekel", symbol: "\u{20AA}", flag: "\u{1F1EE}\u{1F1F1}"),
        Currency(code: "EGP", name: "Egyptian Pound", symbol: "\u{00A3}", flag: "\u{1F1EA}\u{1F1EC}"),
        Currency(code: "NGN", name: "Nigerian Naira", symbol: "\u{20A6}", flag: "\u{1F1F3}\u{1F1EC}"),
        Currency(code: "KES", name: "Kenyan Shilling", symbol: "KSh", flag: "\u{1F1F0}\u{1F1EA}"),
        Currency(code: "NZD", name: "New Zealand Dollar", symbol: "$", flag: "\u{1F1F3}\u{1F1FF}"),
    ]
}

// MARK: - Image Picker
struct OnboardingImagePicker: UIViewControllerRepresentable {
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
        let parent: OnboardingImagePicker
        init(_ parent: OnboardingImagePicker) { self.parent = parent }
        
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
