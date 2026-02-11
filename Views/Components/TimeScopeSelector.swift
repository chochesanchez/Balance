import SwiftUI

// MARK: - Time Scope Selector
/// Reusable time range selector (Daily/Weekly/Monthly/Yearly) with iOS 17 animations
struct TimeScopeSelector: View {
    @Binding var selected: TimeRange
    var showAllOptions: Bool = true
    var onChange: ((TimeRange) -> Void)? = nil
    
    private var options: [TimeRange] {
        if showAllOptions {
            return TimeRange.allCases
        } else {
            return [.weekly, .monthly, .yearly]
        }
    }
    
    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            ForEach(options) { range in
                TimeScopePill(
                    title: range.title,
                    isSelected: selected == range,
                    action: {
                        withAnimation(Theme.Animation.snappy) {
                            selected = range
                        }
                        onChange?(range)
                        Haptics.selection()
                    }
                )
            }
        }
        .padding(Theme.Spacing.xxs)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(Capsule())
    }
}

// MARK: - Time Scope Pill
struct TimeScopePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(isSelected ? Theme.Colors.primary : Color.clear)
                .foregroundStyle(isSelected ? .white : Theme.Colors.secondaryText)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .contentTransition(.interpolate)
    }
}

// MARK: - Compact Time Scope Selector
/// Smaller version for inline use (dropdown menu)
struct CompactTimeScopeSelector: View {
    @Binding var selected: TimeRange
    var onChange: ((TimeRange) -> Void)? = nil
    
    var body: some View {
        Menu {
            ForEach(TimeRange.allCases) { range in
                Button(action: {
                    withAnimation(Theme.Animation.snappy) {
                        selected = range
                    }
                    onChange?(range)
                    Haptics.selection()
                }) {
                    HStack {
                        Text(range.title)
                        if selected == range {
                            Image(systemName: Theme.Icons.checkmark)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.xxs) {
                Text(selected.title)
                    .font(.system(size: 13, weight: .medium))
                Image(systemName: Theme.Icons.chevronDown)
                    .font(.system(size: 10))
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.Colors.primary.opacity(0.1))
            .foregroundStyle(Theme.Colors.primary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TimeScopeSelector(selected: .constant(.monthly))
        TimeScopeSelector(selected: .constant(.weekly), showAllOptions: false)
        CompactTimeScopeSelector(selected: .constant(.monthly))
    }
    .padding()
}
