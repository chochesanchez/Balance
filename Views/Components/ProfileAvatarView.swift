import SwiftUI

// MARK: - Profile Avatar
struct ProfileAvatarView: View {
    let imageData: Data?
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(width: size, height: size)

            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
        .accessibilityHidden(true) // decorative — parent provides label
    }
}

// MARK: - Profile Detail (redirects to full profile in More)
struct ProfileDetailView: View {
    @ObservedObject var viewModel: BalanceViewModel

    var body: some View {
        NewProfileView(viewModel: viewModel)
    }
}
