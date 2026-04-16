import SwiftUI

@main
struct BalancedApp: App {
    @StateObject private var viewModel = BalancedViewModel()

    init() {
        BalancedShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel)
        }
    }
}

struct RootView: View {
    @ObservedObject var viewModel: BalancedViewModel
    
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
            BalancedShortcuts.updateAppShortcutParameters()
        }
    }
}
