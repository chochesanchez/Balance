import SwiftUI

// MARK: - Insight Card
/// Displays a smart insight with contextual styling
struct InsightCard: View {
    let insight: Insight
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: insight.icon ?? insight.severity.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(insight.severity.color)
                    
                    Text(insight.title)
                        .font(Theme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.primaryText)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                Text(insight.message)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let actionLabel = insight.actionLabel {
                    Text(actionLabel)
                        .font(Theme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.primary)
                        .padding(.top, Theme.Spacing.xxs)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(width: 260, alignment: .leading)
            .background(insight.severity.color.opacity(0.1))
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(insight.severity.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Insights Carousel
/// Horizontal scrolling carousel of insight cards
struct InsightsCarousel: View {
    let insights: [Insight]
    var onInsightTap: ((Insight) -> Void)? = nil
    
    var body: some View {
        if insights.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Insights")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(insights) { insight in
                            InsightCard(insight: insight) {
                                onInsightTap?(insight)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Compact Insight Row
/// Single-line insight for inline display
struct CompactInsightRow: View {
    let insight: Insight
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: insight.icon ?? insight.severity.icon)
                .font(.system(size: 14))
                .foregroundColor(insight.severity.color)
                .frame(width: 20)
            
            Text(insight.message)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .lineLimit(1)
        }
        .padding(Theme.Spacing.sm)
        .background(insight.severity.color.opacity(0.08))
        .cornerRadius(Theme.CornerRadius.small)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        InsightCard(insight: Insight(
            type: .savings,
            title: "Great savings! 🎉",
            message: "You're saving 25% of your income this month. Keep it up!",
            severity: .positive
        ))
        
        InsightCard(insight: Insight(
            type: .spending,
            title: "Spending is up",
            message: "Your expenses are 18% higher than last month.",
            severity: .warning
        ))
        
        InsightCard(insight: Insight(
            type: .tip,
            title: "Quick tip",
            message: "Try to save at least 20% of your income each month.",
            severity: .neutral,
            actionLabel: "Learn more"
        ))
        
        CompactInsightRow(insight: Insight(
            type: .habit,
            title: "Reminder",
            message: "3 bills coming up this week (~$150)",
            severity: .neutral
        ))
    }
    .padding()
}
