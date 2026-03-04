import SwiftUI

// MARK: - Section Header
struct HomeSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundColor(Color(uiColor: .label))

            Spacer()

            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Home Header
struct HomeHeader: View {
    @ObservedObject var viewModel: BalanceViewModel

    var body: some View {
        NavigationLink(destination: ProfileDetailView(viewModel: viewModel)) {
            HStack(spacing: Theme.Spacing.sm) {
                ProfileAvatarView(imageData: viewModel.userProfile.profileImageData, size: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Welcome")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Color(uiColor: .secondaryLabel))

                    Text(viewModel.userProfile.name.isEmpty ? "Balance" : viewModel.userProfile.name)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Color(uiColor: .label))
                }

                Spacer()
            }
        }
        .accessibilityLabel("Profile: \(viewModel.userProfile.name.isEmpty ? "Balance" : viewModel.userProfile.name)")
        .accessibilityHint("Tap to view your profile")
        .padding(.vertical, Theme.Spacing.xxs)
    }
}
