import SwiftUI

// MARK: - Balance Design System v2
// Centralized theme following Apple HIG with iOS 17+ features

struct Theme {
    
    // MARK: - Colors
    struct Colors {
        // Primary Brand Color
        static let primary = Color(hex: "0191FF")
        
        // Semantic Colors
        static let income = Color(hex: "34C759")      // System Green
        static let expense = Color(hex: "FF3B30")      // System Red
        static let transfer = Color(hex: "0191FF")     // App blue for transfers
        static let recurring = Color(hex: "FF9500")    // Orange for recurring
        static let goals = Color(hex: "FFCC00")        // Yellow for goals
        
        // Background Colors
        static let background = Color(uiColor: .systemGroupedBackground)
        static let secondaryBackground = Color(uiColor: .secondarySystemGroupedBackground)
        static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
        
        // Text Colors
        static let primaryText = Color(uiColor: .label)
        static let secondaryText = Color(uiColor: .secondaryLabel)
        static let tertiaryText = Color(uiColor: .tertiaryLabel)
        static let placeholderText = Color(uiColor: .placeholderText)
        
        // UI Element Colors
        static let separator = Color(uiColor: .separator)
        static let border = Color(uiColor: .separator)
        static let iconDefault = Color(uiColor: .secondaryLabel)
        
        // Category Colors (for user selection)
        static let categoryColors: [Color] = [
            // Red spectrum
            Color(hex: "FF3B30"), // Red
            Color(hex: "FF6259"), // Coral
            Color(hex: "FF2D55"), // Rose
            // Orange spectrum
            Color(hex: "FF9500"), // Orange
            Color(hex: "FF6F20"), // Tangerine
            Color(hex: "C8651B"), // Burnt Orange
            // Yellow spectrum
            Color(hex: "FFCC00"), // Yellow
            Color(hex: "FFD60A"), // Amber
            // Green spectrum
            Color(hex: "A8D84E"), // Lime
            Color(hex: "34C759"), // Green
            Color(hex: "30B050"), // Forest
            Color(hex: "00C7BE"), // Teal
            // Blue spectrum
            Color(hex: "5AC8FA"), // Sky
            Color(hex: "0191FF"), // Blue
            Color(hex: "007AFF"), // Royal Blue
            Color(hex: "2C5EBF"), // Navy
            // Purple spectrum
            Color(hex: "5856D6"), // Indigo
            Color(hex: "AF52DE"), // Purple
            Color(hex: "BF5AF2"), // Violet
            Color(hex: "9B59B6"), // Plum
            // Pink spectrum
            Color(hex: "FF69B4"), // Hot Pink
            Color(hex: "E8549A"), // Magenta
            // Neutrals
            Color(hex: "8E8E93"), // Grey
            Color(hex: "3A3A3C"), // Charcoal
        ]
    }
    
    // MARK: - Gradients
    struct Gradients {
        static let income = LinearGradient(
            colors: [Colors.income, Colors.income.opacity(0.7)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let expense = LinearGradient(
            colors: [Colors.expense, Colors.expense.opacity(0.7)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let primary = LinearGradient(
            colors: [Colors.primary, Colors.primary.opacity(0.8)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let card = LinearGradient(
            colors: [Colors.cardBackground, Colors.cardBackground.opacity(0.95)],
            startPoint: .top, endPoint: .bottom
        )
        static let shimmer = LinearGradient(
            colors: [Color.clear, Color.white.opacity(0.4), Color.clear],
            startPoint: .leading, endPoint: .trailing
        )
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.bold()
        static let title1 = Font.title.bold()
        static let title2 = Font.title2.bold()
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // Special styles
        static let balanceHero = Font.system(size: 42, weight: .bold, design: .rounded)
        static let balanceAmount = Font.system(size: 34, weight: .bold, design: .rounded)
        static let amountInput = Font.system(size: 48, weight: .semibold, design: .rounded)
        static let transactionAmount = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let statValue = Font.system(size: 15, weight: .semibold, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let card: CGFloat = 16
        static let pill: CGFloat = 100
    }
    
    // MARK: - Sizes (extracted from hardcoded values)
    struct Sizes {
        // Icons
        static let iconSmall: CGFloat = 28
        static let iconMedium: CGFloat = 36
        static let iconLarge: CGFloat = 44
        static let iconXL: CGFloat = 48
        static let iconHero: CGFloat = 60
        
        // Cards
        static let accountCardWidth: CGFloat = 110
        static let miniChartSize: CGFloat = 80
        
        // Progress
        static let progressBarHeight: CGFloat = 6
        static let progressBarThick: CGFloat = 8
        
        // Tab Bar
        static let tabBarHeight: CGFloat = 80
        static let tabBarButtonSize: CGFloat = 44
        static let tabBarCenterSize: CGFloat = 56
        
        // Minimum tap target (Apple HIG)
        static let minTapTarget: CGFloat = 44
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let card = Shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        static let elevated = Shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
        static let subtle = Shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        static let tabBar = Shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: -4)
        static let fab = Shadow(color: Color(hex: "0191FF").opacity(0.35), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Animations (iOS 17+ spring presets)
    struct Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(duration: 0.5, bounce: 0.3)
        static let smooth = SwiftUI.Animation.smooth(duration: 0.35)
        static let snappy = SwiftUI.Animation.snappy(duration: 0.3)
        
        // Stagger helpers
        static func stagger(_ index: Int, base: Double = 0.05) -> SwiftUI.Animation {
            .spring(duration: 0.5, bounce: 0.3).delay(Double(index) * base)
        }
    }
    
    // MARK: - Icons (SF Symbols 7)
    struct Icons {
        // Tab Bar
        static let home = "house.fill"
        static let homeOutline = "house"
        static let history = "clock.fill"
        static let historyOutline = "clock"
        static let record = "plus.circle.fill"
        static let wallet = "wallet.bifold.fill"
        static let walletOutline = "wallet.bifold"
        static let more = "ellipsis"
        static let moreOutline = "ellipsis"
        
        // Transaction Types
        static let income = "arrow.down.circle.fill"
        static let expense = "arrow.up.circle.fill"
        static let transfer = "arrow.left.arrow.right.circle.fill"
        
        // Accounts
        static let cash = "dollarsign.circle.fill"
        static let checking = "building.columns.fill"
        static let savings = "banknote.fill"
        static let creditCard = "creditcard.fill"
        static let investment = "chart.line.uptrend.xyaxis.circle.fill"
        
        // Categories
        static let food = "fork.knife"
        static let transport = "car.fill"
        static let entertainment = "film.fill"
        static let shopping = "bag.fill"
        static let health = "heart.fill"
        static let housing = "house.fill"
        static let subscriptions = "repeat.circle.fill"
        static let salary = "briefcase.fill"
        static let freelance = "laptopcomputer"
        static let gift = "gift.fill"
        static let education = "graduationcap.fill"
        static let fitness = "figure.run"
        
        // UI Actions
        static let add = "plus"
        static let edit = "pencil"
        static let delete = "trash"
        static let search = "magnifyingglass"
        static let filter = "line.3.horizontal.decrease.circle"
        static let filterActive = "line.3.horizontal.decrease.circle.fill"
        static let chevronRight = "chevron.right"
        static let chevronDown = "chevron.down"
        static let checkmark = "checkmark"
        static let close = "xmark"
        static let settings = "gearshape.fill"
        static let profile = "person.crop.circle.fill"
        static let profileOutline = "person.crop.circle"
        static let analytics = "chart.bar.fill"
        static let goals = "target"
        static let tips = "lightbulb.max.fill"
        static let help = "questionmark.circle.fill"
        static let notification = "bell.fill"
        static let notificationBadge = "bell.badge.fill"
        static let calendar = "calendar"
        static let streak = "flame.fill"
        static let share = "square.and.arrow.up"
        static let lock = "lock.fill"
        static let recurring = "repeat.circle.fill"
        static let refresh = "arrow.clockwise"
    }
}

// MARK: - Shadow Model
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - View Extensions

extension View {
    // MARK: Card Styles
    func balanceCardStyle() -> some View {
        self
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large, style: .continuous))
            .shadow(
                color: Theme.Shadows.card.color,
                radius: Theme.Shadows.card.radius,
                x: Theme.Shadows.card.x,
                y: Theme.Shadows.card.y
            )
    }
    
    func glassCard() -> some View {
        self
            .padding(Theme.Spacing.lg)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large, style: .continuous))
    }
    
    // MARK: Button Styles
    func primaryButtonStyle() -> some View {
        self
            .font(Theme.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(Theme.Typography.headline)
            .foregroundColor(Theme.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium, style: .continuous))
    }
    
    // MARK: Entrance Animations
    func slideUpAppear(delay: Double = 0) -> some View {
        modifier(SlideUpAppearModifier(delay: delay))
    }
    
    func fadeInAppear(delay: Double = 0) -> some View {
        modifier(FadeInAppearModifier(delay: delay))
    }
    
    // MARK: Shimmer Loading Effect
    func shimmerEffect() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Slide Up Appear Modifier
struct SlideUpAppearModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(duration: 0.5, bounce: 0.3).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Fade In Appear Modifier
struct FadeInAppearModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.95)
            .onAppear {
                withAnimation(.smooth(duration: 0.4).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Theme.Gradients.shimmer
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 3)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Animated Number Text
struct AnimatedBalanceText: View {
    let value: Double
    let currency: String
    let font: Font
    let color: Color
    
    init(value: Double, currency: String = "USD", font: Font = Theme.Typography.balanceHero, color: Color = Theme.Colors.primaryText) {
        self.value = value
        self.currency = currency
        self.font = font
        self.color = color
    }
    
    var body: some View {
        Text(formatted)
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: value))
            .animation(.snappy(duration: 0.4), value: value)
    }
    
    private var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Press Effect Button Style
struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Haptic Feedback
struct Haptics {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
