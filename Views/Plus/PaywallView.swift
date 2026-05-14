import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var subscription: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing: Bool = false
    @State private var purchaseError: String? = nil

    private var monthly: Product? { subscription.availableProducts.first { $0.id == SubscriptionManager.ProductID.monthly } }
    private var yearly: Product?  { subscription.availableProducts.first { $0.id == SubscriptionManager.ProductID.yearly } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    featureList
                    pricingCards
                    actionButtons
                    legalAndRestore
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Balance Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .accessibilityLabel("Close paywall")
                }
            }
            .task { await subscription.refresh() }
            .alert("Purchase Failed", isPresented: Binding(get: { purchaseError != nil }, set: { if !$0 { purchaseError = nil } })) {
                Button("OK") { purchaseError = nil }
            } message: {
                Text(purchaseError ?? "")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
                    .accessibilityHidden(true)
            }
            Text("Smarter money guidance for students.")
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
            Text("AI insights, advanced analytics, unlimited goals, and smarter saving recommendations.")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            feature("Ask Balance — AI assistant",
                    "Private, on-device-first answers about your spending, savings and goals.",
                    icon: "bubble.left.and.text.bubble.right.fill")
            feature("Advanced analytics",
                    "Trends, anomalies, monthly summaries and projected month-end spend.",
                    icon: "chart.line.uptrend.xyaxis")
            feature("Smarter saving plans",
                    "Personalised weekly targets and goal recommendations.",
                    icon: "target")
            feature("Unlimited goals & pots",
                    "Track every milestone without limits.",
                    icon: "infinity")
            feature("Priority support",
                    "Email-back the developer when you need help.",
                    icon: "envelope.fill")
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    @ViewBuilder
    private func feature(_ title: String, _ subtitle: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(subtitle).font(.system(size: 12)).foregroundColor(Color(uiColor: .secondaryLabel))
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    private var pricingCards: some View {
        VStack(spacing: 10) {
            if subscription.availableProducts.isEmpty && !subscription.isLoading {
                comingSoon
            } else {
                if let monthly = monthly { priceRow(product: monthly, badge: nil) }
                if let yearly = yearly  { priceRow(product: yearly,  badge: bestValueBadge(monthly: monthly, yearly: yearly)) }
                if subscription.isLoading {
                    ProgressView().padding(.top, 4)
                }
            }
        }
    }

    private func bestValueBadge(monthly: Product?, yearly: Product?) -> String? {
        guard let monthly = monthly, let yearly = yearly else { return "Best value" }
        let monthlyYearTotal = NSDecimalNumber(decimal: monthly.price).doubleValue * 12
        let yearlyPrice = NSDecimalNumber(decimal: yearly.price).doubleValue
        let savings = monthlyYearTotal - yearlyPrice
        guard savings > 0, monthlyYearTotal > 0 else { return "Best value" }
        let percent = Int((savings / monthlyYearTotal) * 100)
        return "Save \(percent)%"
    }

    private func priceRow(product: Product, badge: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.system(size: 16, weight: .semibold))
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.income)
                                .clipShape(Capsule())
                        }
                    }
                    Text(product.description)
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    if product.id == SubscriptionManager.ProductID.monthly {
                        Text("per month").font(.system(size: 11)).foregroundColor(Color(uiColor: .secondaryLabel))
                    } else if product.id == SubscriptionManager.ProductID.yearly {
                        Text("per year").font(.system(size: 11)).foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
            }
            Button {
                Task { await purchase(product) }
            } label: {
                if purchasing {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                } else {
                    Text(subscription.effectiveIsPlus ? "Current plan" : "Start Plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
            .background(subscription.effectiveIsPlus ? Color(uiColor: .systemGray3) : Theme.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(purchasing || subscription.effectiveIsPlus)
            .accessibilityLabel("Start \(product.displayName) for \(product.displayPrice)")
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var comingSoon: some View {
        VStack(spacing: 8) {
            Image(systemName: "hammer.fill")
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .accessibilityHidden(true)
            Text("Balance Plus is rolling out.")
                .font(.system(size: 14, weight: .semibold))
            Text("In-app purchase will appear here once available in your region.")
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            if subscription.effectiveIsPlus {
                Button("Manage Subscription") {
                    Task { await subscription.openManageSubscriptions() }
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundColor(Theme.Colors.primary)
            }
            Button("Continue Free") {
                dismiss()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }

    private var legalAndRestore: some View {
        VStack(spacing: 8) {
            restoreStateBanner

            Text("Already subscribed?")
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: .secondaryLabel))

            Button {
                Task { await subscription.restore() }
            } label: {
                Text(subscription.restoreState == .running ? "Restoring…" : "Restore Purchases")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Theme.Colors.primary.opacity(0.08))
                    .clipShape(Capsule())
            }
            .disabled(subscription.restoreState == .running)
            .accessibilityLabel("Restore Purchases")

            Text("Subscriptions auto-renew until cancelled. Cancel anytime in Settings → Apple ID → Subscriptions. Purchases belong to the original Apple ID — restoring on a different Apple ID won't recover them. Balance provides educational insights, not professional financial advice.")
                .font(.system(size: 10))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var restoreStateBanner: some View {
        switch subscription.restoreState {
        case .success(let plus):
            HStack(spacing: 10) {
                Image(systemName: plus ? "checkmark.seal.fill" : "info.circle.fill")
                    .foregroundColor(plus ? Theme.Colors.income : Theme.Colors.primary)
                    .accessibilityHidden(true)
                Text(plus ? "Balance Plus restored." : "No active purchases found on this Apple ID.")
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Button(action: { subscription.clearRestoreState() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .accessibilityLabel("Dismiss restore message")
            }
            .padding(12)
            .background((plus ? Theme.Colors.income : Theme.Colors.primary).opacity(0.1))
            .cornerRadius(10)
            .transition(.opacity)
        case .failure(let message):
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.Colors.expense)
                    .accessibilityHidden(true)
                Text("Restore failed: \(message)")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Button(action: { subscription.clearRestoreState() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .accessibilityLabel("Dismiss restore error")
            }
            .padding(12)
            .background(Theme.Colors.expense.opacity(0.1))
            .cornerRadius(10)
            .transition(.opacity)
        case .idle, .running:
            EmptyView()
        }
    }

    private func purchase(_ product: Product) async {
        purchasing = true
        defer { purchasing = false }
        let ok = await subscription.purchase(product)
        if !ok, let err = subscription.lastError {
            purchaseError = err
        }
    }
}
