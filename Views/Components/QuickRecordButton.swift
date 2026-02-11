import SwiftUI

// MARK: - Quick Record Floating Action Button
/// A reusable floating action button for quick transaction recording
struct QuickRecordButton: View {
    let action: () -> Void
    var size: CGFloat = Theme.Sizes.tabBarCenterSize
    
    var body: some View {
        Button(action: {
            action()
            Haptics.medium()
        }) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: size, height: size)
                    .shadow(
                        color: Theme.Shadows.fab.color,
                        radius: Theme.Shadows.fab.radius,
                        x: Theme.Shadows.fab.x,
                        y: Theme.Shadows.fab.y
                    )
                
                Image(systemName: Theme.Icons.add)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

// MARK: - Quick Action Pill
/// Horizontal pill button for Income / Expense / Transfer quick actions
struct QuickActionPill: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            Haptics.light()
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(Theme.Typography.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        QuickRecordButton(action: {})
        
        HStack(spacing: Theme.Spacing.sm) {
            QuickActionPill(icon: Theme.Icons.income, label: "Income", color: Theme.Colors.income, action: {})
            QuickActionPill(icon: Theme.Icons.expense, label: "Expense", color: Theme.Colors.expense, action: {})
            QuickActionPill(icon: Theme.Icons.transfer, label: "Transfer", color: Theme.Colors.transfer, action: {})
        }
    }
    .padding()
}
