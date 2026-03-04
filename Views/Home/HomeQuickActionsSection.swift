import SwiftUI

// MARK: - Quick Actions Row
struct QuickActionsRow: View {
    let onAction: (TransactionType) -> Void
    var onRecurring: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            QuickActionButton(icon: "arrow.down", label: "Income", color: Theme.Colors.income) {
                onAction(.income)
            }
            QuickActionButton(icon: "arrow.up", label: "Expense", color: Theme.Colors.expense) {
                onAction(.expense)
            }
            QuickActionButton(icon: "arrow.left.arrow.right", label: "Transfer", color: Theme.Colors.primary) {
                onAction(.transfer)
            }
            // FIX B1: "Recurring" now triggers its own callback so RecordView opens
            // with isRecurring pre-enabled, not just expense type pre-selected.
            QuickActionButton(icon: "repeat", label: "Recurring", color: Theme.Colors.recurring) {
                onRecurring?() ?? onAction(.expense)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.CornerRadius.large)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            Haptics.light()
        }) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: Theme.Sizes.minTapTarget - 2, height: Theme.Sizes.minTapTarget - 2)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(uiColor: .label))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressEffectButtonStyle())
        .accessibilityLabel(label)
        .accessibilityHint("Quick record \(label)")
    }
}
