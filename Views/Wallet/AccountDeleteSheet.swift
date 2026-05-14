import SwiftUI

struct AccountDeleteSheet: View {
    @ObservedObject var viewModel: BalancedViewModel
    let account: Account
    var onCompleted: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .archive
    @State private var destinationId: UUID?

    enum Mode: String, Identifiable, CaseIterable {
        case transfer, remove, archive
        var id: String { rawValue }
    }

    private var balance: Double { viewModel.balanceForAccount(account) }
    private var hasBalance: Bool { abs(balance) > 0.005 }
    private var hasHistory: Bool { viewModel.transactions.contains { $0.accountId == account.id || $0.toAccountId == account.id } }

    private var otherAccounts: [Account] {
        viewModel.accounts.filter { $0.id != account.id && !$0.isArchived }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header

                    if hasBalance {
                        Text("This account still has money.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(uiColor: .label))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                    }

                    VStack(spacing: 10) {
                        if !otherAccounts.isEmpty {
                            optionRow(.transfer, title: "Transfer balance to another account",
                                      subtitle: "Move the remaining \(formatCurrency(balance, currency: viewModel.appState.selectedCurrency)) and close this account.",
                                      icon: "arrow.left.arrow.right.circle.fill",
                                      color: Theme.Colors.primary)
                        }
                        if hasHistory || account.isDefault == false {
                            optionRow(.archive, title: "Archive account instead",
                                      subtitle: "Hide it from active selectors, keep history. You can unarchive later.",
                                      icon: "archivebox.fill",
                                      color: Color(uiColor: .systemGray))
                        } else {
                            optionRow(.archive, title: "Archive account",
                                      subtitle: "Recommended. Hide it, keep history. Reversible.",
                                      icon: "archivebox.fill",
                                      color: Color(uiColor: .systemGray))
                        }
                        optionRow(.remove, title: hasBalance ? "Delete and remove balance" : "Delete account",
                                  subtitle: hasBalance ? "The \(formatCurrency(balance, currency: viewModel.appState.selectedCurrency)) is removed without affecting income or expense analytics."
                                                       : "Permanently deletes the account.",
                                  icon: "trash.fill",
                                  color: Theme.Colors.expense)
                    }
                    .padding(.horizontal, 16)

                    if mode == .transfer && !otherAccounts.isEmpty {
                        destinationPicker
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 12)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Close Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                primaryButton
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Color(uiColor: .systemBackground).opacity(0.95))
            }
            .onAppear {
                destinationId = otherAccounts.first?.id
                if otherAccounts.isEmpty || !hasBalance {
                    mode = .archive
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(account.colorValue.opacity(0.15)).frame(width: 64, height: 64)
                Image(systemName: account.icon)
                    .font(.system(size: 26))
                    .foregroundColor(account.colorValue)
                    .accessibilityHidden(true)
            }
            Text(account.name).font(.system(size: 18, weight: .semibold))
            Text(formatCurrency(balance, currency: viewModel.appState.selectedCurrency))
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func optionRow(_ option: Mode, title: String, subtitle: String, icon: String, color: Color) -> some View {
        let selected = mode == option
        Button {
            withAnimation(.snappy) { mode = option }
            Haptics.selection()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(Color(uiColor: .label))
                    Text(subtitle).font(.system(size: 12)).foregroundColor(Color(uiColor: .secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                if selected { Image(systemName: "checkmark.circle.fill").foregroundColor(color).accessibilityHidden(true) }
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(selected ? color : .clear, lineWidth: 2))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private var destinationPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TRANSFER TO")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(otherAccounts) { acc in
                        let selected = destinationId == acc.id
                        Button {
                            withAnimation(.snappy) { destinationId = acc.id }
                            Haptics.selection()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: acc.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(selected ? .white : acc.colorValue)
                                    .frame(width: 44, height: 44)
                                    .background(selected ? acc.colorValue : acc.colorValue.opacity(0.12))
                                    .clipShape(Circle())
                                    .accessibilityHidden(true)
                                Text(acc.name).font(.system(size: 11, weight: selected ? .semibold : .regular))
                                    .foregroundColor(selected ? Color(uiColor: .label) : Color(uiColor: .secondaryLabel))
                                    .lineLimit(1)
                            }
                            .frame(width: 72)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(acc.name)
                        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 6)
    }

    private var primaryButton: some View {
        Button(action: confirm) {
            Text(primaryTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(primaryBackground)
                .cornerRadius(14)
        }
        .disabled(!canConfirm)
    }

    private var primaryTitle: String {
        switch mode {
        case .transfer: return "Transfer & Close"
        case .archive: return "Archive Account"
        case .remove: return "Delete Account"
        }
    }

    private var primaryBackground: Color {
        if !canConfirm { return Color(uiColor: .systemGray3) }
        switch mode {
        case .transfer: return Theme.Colors.primary
        case .archive: return Theme.Colors.primary
        case .remove: return Theme.Colors.expense
        }
    }

    private var canConfirm: Bool {
        switch mode {
        case .transfer: return destinationId != nil
        case .archive, .remove: return true
        }
    }

    private func confirm() {
        switch mode {
        case .transfer:
            guard let destinationId else { return }
            viewModel.closeAccountByTransferring(account, toAccountId: destinationId)
        case .archive:
            viewModel.archiveAccount(account)
        case .remove:
            if hasBalance {
                viewModel.deleteAccountAndRemoveBalance(account)
            } else {
                viewModel.deleteAccount(account)
            }
        }
        Haptics.success()
        onCompleted()
        dismiss()
    }
}
