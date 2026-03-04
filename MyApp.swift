import SwiftUI

@main
struct BalanceApp: App {
    @StateObject private var viewModel = BalanceViewModel()

    init() {
        BalanceShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel)
        }
    }
}

struct RootView: View {
    @ObservedObject var viewModel: BalanceViewModel
    
    var body: some View {
        Group {
            if viewModel.hasCompletedOnboarding {
                MainTabView(viewModel: viewModel)
            } else {
                AuthGateView(viewModel: viewModel)
            }
        }
        .animation(.easeInOut, value: viewModel.hasCompletedOnboarding)
        .task {
            BalanceShortcuts.updateAppShortcutParameters()
        }
    }
}
