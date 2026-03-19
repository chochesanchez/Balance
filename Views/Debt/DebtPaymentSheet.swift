import SwiftUI

// MARK: - Debt Payment Sheet
struct DebtPaymentSheet: View {
    @ObservedObject var viewModel: BalanceViewModel
    let debt: Debt
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var paymentDate = Date()
    @State private var note = ""
    @State private var markSettled = false
    @State private var selectedAccountId: UUID?
    @FocusState private var amountFocused: Bool

    private let debtColor = Color(hex: "FF3B30")

    private var parsedAmount: Double? {
        let cleaned = amountText.replacingOccurrences(of: ",", with: ".")
        guard let v = Double(cleaned), v > 0 else { return nil }
        return min(v, debt.remaining + 0.01)
    }

    private var isValid: Bool { parsedAmount != nil }

    private var liveDebt: Debt {
        viewModel.debts.first(where: { $0.id == debt.id }) ?? debt
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(debtColor.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: liveDebt.icon)
                            .font(.system(size: 28))
                            .foregroundColor(debtColor)
                    }
                    Text(liveDebt.title)
                        .font(.system(size: 17, weight: .semibold))
                    HStack(spacing: 4) {
                        Text("Remaining:")
                            .font(.system(size: 13))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        Text(formatCurrency(liveDebt.remaining, currency: viewModel.appState.selectedCurrency))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(debtColor)
                    }
                }
                .padding(.top, 8)

                // Amount
                VStack(spacing: 4) {
                    Text("Payment Amount")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    HStack(spacing: 4) {
                        Text(Locale.current.currencySymbol ?? "$")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(uiColor: .label).opacity(amountText.isEmpty ? 0.25 : 1))
                        TextField("0", text: $amountText)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(uiColor: .label))
                            .focused($amountFocused)
                    }
                    .frame(maxWidth: 200)
                }
                .contentShape(Rectangle())
                .onTapGesture { amountFocused = true }

                // Account picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(liveDebt.type == .iOwe ? "PAID FROM" : "RECEIVED TO")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.accounts) { account in
                                let selected = selectedAccountId == account.id
                                Button {
                                    withAnimation(.snappy) { selectedAccountId = account.id }
                                    Haptics.selection()
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: account.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(selected ? .white : account.colorValue)
                                            .frame(width: 36, height: 36)
                                            .background(selected ? account.colorValue : account.colorValue.opacity(0.12))
                                            .clipShape(Circle())
                                        Text(account.name)
                                            .font(.system(size: 11, weight: selected ? .semibold : .regular))
                                            .foregroundColor(selected ? Color(uiColor: .label) : Color(uiColor: .secondaryLabel))
                                            .lineLimit(1)
                                    }
                                    .frame(width: 64)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // Date + note
                VStack(spacing: 0) {
                    HStack {
                        Text("Date")
                            .font(.system(size: 15))
                        Spacer()
                        DatePicker("", selection: $paymentDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)

                    Divider().padding(.leading, 16)

                    HStack {
                        Text("Note")
                            .font(.system(size: 15))
                        Spacer()
                        TextField("Optional", text: $note)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 15))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(14)
                .padding(.horizontal, 20)

                // Mark settled toggle
                if let amount = parsedAmount, amount >= liveDebt.remaining - 0.01 {
                    Toggle("Mark debt as fully settled", isOn: $markSettled)
                        .tint(Color(hex: "34C759"))
                        .padding(.horizontal, 20)
                        .font(.system(size: 15))
                }

                Spacer()

                Button(action: record) {
                    Text(liveDebt.type == .iOwe ? "Record Payment" : "Record Receipt")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(isValid ? debtColor : debtColor.opacity(0.3))
                        .cornerRadius(14)
                }
                .disabled(!isValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(liveDebt.type == .iOwe ? "Record Payment" : "Record Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if amountFocused {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { amountFocused = false }
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private func record() {
        guard let amount = parsedAmount else { return }
        let payment = DebtPayment(amount: amount, date: paymentDate, note: note)
        viewModel.recordDebtPayment(payment, debtId: liveDebt.id, fromAccountId: selectedAccountId)
        if markSettled {
            if var updated = viewModel.debts.first(where: { $0.id == liveDebt.id }) {
                updated.isSettled = true
                viewModel.updateDebt(updated)
            }
        }
        Haptics.success()
        dismiss()
    }
}
