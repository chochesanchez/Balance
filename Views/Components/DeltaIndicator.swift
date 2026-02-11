import SwiftUI

struct DeltaIndicator: View {
    let deltaPercent: Double
    let comparisonLabel: String
    var invertColors: Bool = false
    
    private var isPositive: Bool {
        deltaPercent >= 0
    }
    
    private var displayPercent: Int {
        Int(abs(deltaPercent * 100))
    }
    
    private var color: Color {
        if invertColors {
            return isPositive ? Theme.Colors.expense : Theme.Colors.income
        } else {
            return isPositive ? Theme.Colors.income : Theme.Colors.expense
        }
    }
    
    private var icon: String {
        isPositive ? "arrow.up.right" : "arrow.down.right"
    }
    
    var body: some View {
        if displayPercent > 0 {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                
                Text("\(isPositive ? "+" : "-")\(displayPercent)%")
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                
                Text(comparisonLabel)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .foregroundColor(color)
        }
    }
}

struct DeltaBadge: View {
    let deltaPercent: Double
    var invertColors: Bool = false
    
    private var isPositive: Bool {
        deltaPercent >= 0
    }
    
    private var displayPercent: Int {
        Int(abs(deltaPercent * 100))
    }
    
    private var color: Color {
        if invertColors {
            return isPositive ? Theme.Colors.expense : Theme.Colors.income
        } else {
            return isPositive ? Theme.Colors.income : Theme.Colors.expense
        }
    }
    
    var body: some View {
        if displayPercent > 0 {
            Text("\(isPositive ? "+" : "-")\(displayPercent)%")
                .font(Theme.Typography.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

struct SavingsRingView: View {
    let saved: Double
    let target: Double
    let currency: String
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(saved / target, 1.0)
    }
    
    private var progressColor: Color {
        if progress >= 1.0 { return Theme.Colors.income }
        else if progress >= 0.7 { return .orange }
        else { return Theme.Colors.primary }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.secondaryBackground, lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5), value: progress)
            
            VStack(spacing: 0) {
                Text(formatCompact(saved))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.primaryText)
                Text("saved")
                    .font(.system(size: 9))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .frame(width: 64, height: 64)
    }
    
    private func formatCompact(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        
        if amount >= 1000 {
            formatter.maximumFractionDigits = 1
            let thousands = amount / 1000
            return "\(formatter.currencySymbol ?? "$")\(String(format: "%.1f", thousands))k"
        }
        
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}

struct MetricDeltaRow: View {
    let title: String
    let value: Double
    let deltaPercent: Double?
    let currency: String
    let icon: String
    let iconColor: Color
    var invertDeltaColors: Bool = false
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                if let delta = deltaPercent, abs(delta) > 0.01 {
                    DeltaIndicator(
                        deltaPercent: delta,
                        comparisonLabel: "vs last",
                        invertColors: invertDeltaColors
                    )
                }
            }
            
            Spacer()
            
            Text(formatCurrency(value, currency: currency))
                .font(Theme.Typography.headline)
                .foregroundColor(iconColor)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DeltaIndicator(deltaPercent: 0.15, comparisonLabel: "vs last month")
        DeltaIndicator(deltaPercent: -0.08, comparisonLabel: "vs last week")
        DeltaIndicator(deltaPercent: 0.25, comparisonLabel: "vs last month", invertColors: true)
        
        HStack {
            DeltaBadge(deltaPercent: 0.18)
            DeltaBadge(deltaPercent: -0.12)
            DeltaBadge(deltaPercent: 0.25, invertColors: true)
        }
        
        SavingsRingView(saved: 450, target: 1000, currency: "USD")
        
        MetricDeltaRow(
            title: "Income",
            value: 2500,
            deltaPercent: 0.12,
            currency: "USD",
            icon: "arrow.down",
            iconColor: Theme.Colors.income
        )
        
        MetricDeltaRow(
            title: "Expenses",
            value: 1800,
            deltaPercent: 0.08,
            currency: "USD",
            icon: "arrow.up",
            iconColor: Theme.Colors.expense,
            invertDeltaColors: true
        )
    }
    .padding()
}
