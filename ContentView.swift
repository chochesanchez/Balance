import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                NewHomeView(viewModel: viewModel)
            }
            .tabItem {
                Label("Home", systemImage: selectedTab == 0 ? Theme.Icons.home : Theme.Icons.homeOutline)
            }
            .tag(0)

            NavigationStack {
                NewHistoryView(viewModel: viewModel)
            }
            .tabItem {
                Label("History", systemImage: selectedTab == 1 ? Theme.Icons.history : Theme.Icons.historyOutline)
            }
            .tag(1)
            
            NavigationStack {
                RecordView(viewModel: viewModel)
            }
            .tabItem {
                Label("Record", systemImage: Theme.Icons.record)
            }
            .tag(2)
            
            NavigationStack {
                WalletView(viewModel: viewModel)
            }
            .tabItem {
                Label("Wallet", systemImage: selectedTab == 3 ? Theme.Icons.wallet : Theme.Icons.walletOutline)
            }
            .tag(3)
            
            NavigationStack {
                MoreView(viewModel: viewModel)
            }
            .tabItem {
                Label("More", systemImage: Theme.Icons.more)
            }
            .tag(4)
        }
        .tint(Theme.Colors.primary)
    }
}

#Preview {
    MainTabView(viewModel: BalanceViewModel())
}
