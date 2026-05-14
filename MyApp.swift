import SwiftUI

@main
struct BalancedApp: App {
    @StateObject private var viewModel = BalancedViewModel()
    @StateObject private var subscription = SubscriptionManager()
    @StateObject private var identity = AppIdentity.shared
    @StateObject private var rating = RatingManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        BalancedShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel, subscription: subscription, identity: identity, rating: rating)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        rating.registerAppForegrounded()
                        Task { await subscription.refresh() }
                    }
                }
        }
    }
}

struct RootView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @ObservedObject var subscription: SubscriptionManager
    @ObservedObject var identity: AppIdentity
    @ObservedObject var rating: RatingManager
    @State private var showWelcome = false
    @AppStorage("balance_has_seen_welcome") private var hasSeenWelcome = false

    var body: some View {
        Group {
            if viewModel.hasCompletedOnboarding {
                MainTabView(viewModel: viewModel, subscription: subscription)
                    .sheet(isPresented: $showWelcome) {
                        WelcomeFlowView(viewModel: viewModel)
                            .onDisappear { hasSeenWelcome = true }
                    }
            } else {
                AuthGateView(viewModel: viewModel)
            }
        }
        .animation(.easeInOut, value: viewModel.hasCompletedOnboarding)
        .task {
            BalancedShortcuts.updateAppShortcutParameters()
            await subscription.refresh()
            if viewModel.hasCompletedOnboarding && !hasSeenWelcome {
                showWelcome = true
            }
        }
        .onChange(of: viewModel.hasCompletedOnboarding) { _, completed in
            if completed && !hasSeenWelcome { showWelcome = true }
        }
    }
}
