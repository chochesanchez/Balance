import SwiftUI

// MARK: - Back Tap Setup Guide
struct BackTapSetupView: View {

    private let shortcutSteps: [(icon: String, color: Color, title: String, subtitle: String)] = [
        ("square.grid.2x2.fill",    Theme.Colors.primary,    "Open Shortcuts",          "Launch the Shortcuts app on your iPhone"),
        ("magnifyingglass",         Color(hex: "8E8E93"),    "Search \"Balance\"",      "Type Balance in the search bar"),
        ("hand.tap.fill",           Theme.Colors.goals,      "Long-press Quick Add",    "Hold the Quick Add shortcut for 3 seconds until a pop-up appears"),
        ("plus.square.fill",        Theme.Colors.income,     "Tap \"New Shortcut\"",    "Select New Shortcut from the pop-up menu"),
        ("slider.horizontal.3",     Theme.Colors.primary,    "Set Ask Each Time",       "Tap the Type field → choose Ask Each Time. Do the same for Account."),
    ]

    private let backTapSteps: [(icon: String, color: Color, title: String, subtitle: String)] = [
        ("gearshape.fill",          Color(hex: "8E8E93"),    "Open Settings",           "Go to Settings on your iPhone"),
        ("accessibility.fill",      Color(hex: "007AFF"),    "Accessibility → Touch",   "Scroll to Accessibility, then tap Touch"),
        ("hand.tap.fill",           Theme.Colors.primary,    "Back Tap",                "Scroll to the bottom of the Touch menu"),
        ("2.circle.fill",           Theme.Colors.goals,      "Double or Triple Tap",    "Choose whichever tap you prefer"),
        ("checkmark.circle.fill",   Theme.Colors.income,     "Shortcuts → Quick Add",   "Scroll to Shortcuts and select your Quick Add shortcut"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 34))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    .padding(.top, 8)

                    Text("Back Tap Quick Record")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(uiColor: .label))

                    Text("Tap the back of your iPhone to instantly record a transaction — no need to open Balance.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 28)

                // Part 1
                sectionHeader(number: "1", title: "Create the Shortcut")
                stepList(shortcutSteps)
                    .padding(.bottom, 24)

                // Part 2
                sectionHeader(number: "2", title: "Assign to Back Tap")
                stepList(backTapSteps)

                // Demo tip
                VStack(spacing: 8) {
                    Label("What you'll see", systemImage: "eye.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)

                    Text("After setup, tapping the back of your iPhone shows a sheet asking for the amount, type, and account. Confirm and the transaction is saved instantly.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(Theme.Colors.primary.opacity(0.06))
                .cornerRadius(Theme.CornerRadius.medium)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, 20)

                // Open Settings button
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Open Settings")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.CornerRadius.large)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, 24)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
                .accessibilityLabel("Open Settings")
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Back Tap Setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func sectionHeader(number: String, title: String) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 22, height: 22)
                Text(number)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func stepList(_ steps: [(icon: String, color: Color, title: String, subtitle: String)]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(step.color.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: step.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(step.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("\(index + 1).")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                            Text(step.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(uiColor: .label))
                        }
                        Text(step.subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                if index < steps.count - 1 {
                    HStack {
                        Rectangle()
                            .fill(Color(uiColor: .separator).opacity(0.5))
                            .frame(width: 1, height: 20)
                            .padding(.leading, 20 + 22)
                        Spacer()
                    }
                }
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.CornerRadius.large)
        .padding(.horizontal, Theme.Spacing.md)
    }
}
