import SwiftUI

// MARK: - Custom Floating Tab Bar
/// A premium floating tab bar with an elevated center "Record" button
struct BalanceTabBar: View {
    @Binding var selectedTab: Int
    let recordAction: () -> Void
    var badgeCounts: [Int: Int] = [:]
    
    private let tabs: [(icon: String, activeIcon: String, label: String)] = [
        (Theme.Icons.homeOutline, Theme.Icons.home, "Home"),
        (Theme.Icons.historyOutline, Theme.Icons.history, "History"),
        ("", "", ""),  // Center placeholder
        (Theme.Icons.walletOutline, Theme.Icons.wallet, "Wallet"),
        (Theme.Icons.moreOutline, Theme.Icons.more, "More"),
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                if index == 2 {
                    // Center Record Button
                    centerButton
                } else {
                    tabButton(index: index)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.lg)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(
                    color: Theme.Shadows.tabBar.color,
                    radius: Theme.Shadows.tabBar.radius,
                    x: Theme.Shadows.tabBar.x,
                    y: Theme.Shadows.tabBar.y
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Tab Button
    private func tabButton(index: Int) -> some View {
        let tab = tabs[index]
        let isActive = selectedTab == index
        
        return Button {
            withAnimation(Theme.Animation.snappy) {
                selectedTab = index
            }
            Haptics.selection()
        } label: {
            VStack(spacing: Theme.Spacing.xxs) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isActive ? tab.activeIcon : tab.icon)
                        .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                        .symbolEffect(.bounce.byLayer, value: isActive)
                    
                    // Badge
                    if let count = badgeCounts[index], count > 0 {
                        Circle()
                            .fill(Theme.Colors.expense)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -2)
                    }
                }
                .frame(width: 28, height: 28)
                
                Text(tab.label)
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular))
            }
            .foregroundStyle(isActive ? Theme.Colors.primary : Theme.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Center Record Button
    private var centerButton: some View {
        Button {
            recordAction()
            Haptics.medium()
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: Theme.Sizes.tabBarCenterSize, height: Theme.Sizes.tabBarCenterSize)
                    .shadow(
                        color: Theme.Shadows.fab.color,
                        radius: Theme.Shadows.fab.radius,
                        x: Theme.Shadows.fab.x,
                        y: Theme.Shadows.fab.y
                    )
                
                Image(systemName: Theme.Icons.add)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .offset(y: -12)
        }
        .buttonStyle(PressEffectButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack {
        Spacer()
        BalanceTabBar(selectedTab: .constant(0), recordAction: {}, badgeCounts: [4: 2])
    }
}
