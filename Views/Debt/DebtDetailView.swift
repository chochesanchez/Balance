import SwiftUI

// MARK: - Debt Detail View
struct DebtDetailView: View {
    @ObservedObject var viewModel: BalancedViewModel
    let debt: Debt
    @Environment(\.dismiss) private var dismiss
    @State private var showPayment = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var showSettledBanner = false

    private let debtColor = Color(hex: "FF3B30")

    private var liveDebt: Debt {
        viewModel.debts.first(where: { $0.id == debt.id }) ?? debt
    }

    private var myRecommendations: [BalancedViewModel.DebtRecommendation] {
        viewModel.debtRecommendations.filter { $0.debtId == debt.id }
    }

    var body: some View {
        List {
            // Header
            Section {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(debtColor.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: liveDebt.icon)
                            .font(.system(size: 32))
                            .foregroundColor(debtColor)
                    }
                    VStack(spacing: 4) {
                        Text(liveDebt.title)
                            .font(.system(size: 20, weight: .bold))
                        if !liveDebt.person.isEmpty {
                            Text(liveDebt.person)
                                .font(.system(size: 14))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                        Label(liveDebt.type.rawValue, systemImage: liveDebt.type == .iOwe ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(liveDebt.type == .iOwe ? debtColor : Color(hex: "34C759"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background((liveDebt.type == .iOwe ? debtColor : Color(hex: "34C759")).opacity(0.1))
                            .clipShape(Capsule())
                    }

                    // Progress bar
                    if liveDebt.totalAmount > 0 {
                        VStack(spacing: 4) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color(uiColor: .tertiarySystemFill))
                                        .frame(height: 10)
                                    Capsule()
                                        .fill(liveDebt.isSettled ? Color(hex: "34C759") : debtColor)
                                        .frame(width: geo.size.width * CGFloat(liveDebt.progress / 100), height: 10)
                                        .animation(.spring, value: liveDebt.progress)
                                }
                            }
                            .frame(height: 10)
                            Text("\(Int(liveDebt.progress))% paid")
                                .font(.system(size: 12))
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                        .padding(.horizontal, 8)
                    }

                    // Action buttons
                    if !liveDebt.isSettled {
                        HStack(spacing: 12) {
                            Button {
                                showPayment = true
                                Haptics.light()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: liveDebt.type == .iOwe ? "plus.circle.fill" : "arrow.down.circle.fill")
                                        .font(.system(size: 14))
                                    Text(liveDebt.type == .iOwe ? "Record Payment" : "Record Receipt")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(debtColor)
                                .cornerRadius(20)
                            }

                            if liveDebt.paidAmount > 0 {
                                Button {
                                    markSettled()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                        Text("Mark Settled")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(Color(hex: "34C759"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: "34C759").opacity(0.1))
                                    .cornerRadius(20)
                                }
                            }
                        }
                    } else {
                        Label("Settled", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "34C759"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(hex: "34C759").opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            // Stats
            Section("Details") {
                statRow("Total Amount", value: formatCurrency(liveDebt.totalAmount, currency: viewModel.appState.selectedCurrency))
                statRow("Paid", value: formatCurrency(liveDebt.paidAmount, currency: viewModel.appState.selectedCurrency), valueColor: Color(hex: "34C759"))
                statRow("Remaining", value: formatCurrency(liveDebt.remaining, currency: viewModel.appState.selectedCurrency), valueColor: liveDebt.isSettled ? Color(uiColor: .secondaryLabel) : debtColor)
                if let due = liveDebt.dueDate {
                    HStack {
                        Text("Due Date")
                        Spacer()
                        HStack(spacing: 4) {
                            if liveDebt.isOverdue {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(debtColor)
                            }
                            Text(due, style: .date)
                                .foregroundColor(liveDebt.isOverdue ? debtColor : Color(uiColor: .secondaryLabel))
                        }
                    }
                }
                if let rate = liveDebt.interestRate {
                    statRow("Interest Rate", value: "\(Int(rate))% per year")
                }
                if !liveDebt.note.isEmpty {
                    HStack(alignment: .top) {
                        Text("Note")
                        Spacer()
                        Text(liveDebt.note)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            // Recommendations
            if !myRecommendations.isEmpty {
                Section("Recommendations") {
                    ForEach(myRecommendations) { rec in
                        HStack(spacing: 12) {
                            Image(systemName: rec.icon)
                                .font(.system(size: 16))
                                .foregroundColor(rec.severity == .warning ? debtColor : rec.severity == .positive ? Color(hex: "34C759") : Theme.Colors.primary)
                                .frame(width: 32)
                            Text(rec.message)
                                .font(.system(size: 14))
                                .foregroundColor(Color(uiColor: .label))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            // Payment history
            if !liveDebt.payments.isEmpty {
                Section("Payment History") {
                    ForEach(liveDebt.payments.sorted { $0.date > $1.date }) { payment in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(payment.date, style: .date)
                                    .font(.system(size: 15))
                                if !payment.note.isEmpty {
                                    Text(payment.note)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(uiColor: .secondaryLabel))
                                }
                            }
                            Spacer()
                            Text(formatCurrency(payment.amount, currency: viewModel.appState.selectedCurrency))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(liveDebt.type == .iOwe ? debtColor : Color(hex: "34C759"))
                        }
                    }
                }
            }

            // Delete
            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Debt")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(liveDebt.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showPayment) {
            DebtPaymentSheet(viewModel: viewModel, debt: liveDebt)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showEdit) {
            EditDebtView(viewModel: viewModel, debt: liveDebt)
        }
        .alert("Delete Debt", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                viewModel.deleteDebt(debt)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the debt and all payment history.")
        }
        .onChange(of: viewModel.debts.map(\.id)) { _, newIds in
            if !newIds.contains(debt.id) { dismiss() }
        }
    }

    @ViewBuilder
    private func statRow(_ label: String, value: String, valueColor: Color = Color(uiColor: .secondaryLabel)) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(valueColor)
        }
    }

    private func markSettled() {
        var updated = liveDebt
        updated.isSettled = true
        viewModel.updateDebt(updated)
        Haptics.success()
    }
}

// MARK: - Edit Debt View
struct EditDebtView: View {
    @ObservedObject var viewModel: BalancedViewModel
    let debt: Debt
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var person: String
    @State private var type: DebtType
    @State private var amountText: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var hasInterest: Bool
    @State private var interestText: String
    @State private var note: String
    @State private var selectedIcon: String

    private let icons = [
        "creditcard.fill", "person.fill", "house.fill",
        "car.fill", "bag.fill", "banknote.fill",
        "stethoscope", "graduationcap.fill", "wrench.fill", "cart.fill"
    ]
    private let debtColor = Color(hex: "FF3B30")

    init(viewModel: BalancedViewModel, debt: Debt) {
        self.viewModel = viewModel
        self.debt = debt
        _title = State(initialValue: debt.title)
        _person = State(initialValue: debt.person)
        _type = State(initialValue: debt.type)
        _amountText = State(initialValue: String(debt.totalAmount))
        _hasDueDate = State(initialValue: debt.dueDate != nil)
        _dueDate = State(initialValue: debt.dueDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date())
        _hasInterest = State(initialValue: debt.interestRate != nil)
        _interestText = State(initialValue: debt.interestRate.map { String($0) } ?? "")
        _note = State(initialValue: debt.note)
        _selectedIcon = State(initialValue: debt.icon)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amountText.replacingOccurrences(of: ",", with: ".")).map { $0 > 0 } ?? false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Debt Details") {
                    HStack {
                        Text("Title"); Spacer()
                        TextField("Title", text: $title).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Person"); Spacer()
                        TextField("Person / Entity", text: $person).multilineTextAlignment(.trailing)
                    }
                    Picker("Type", selection: $type) {
                        ForEach(DebtType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    HStack {
                        Text("Total Amount"); Spacer()
                        TextField("0.00", text: $amountText).multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                    }
                }
                Section("Due Date") {
                    Toggle("Has due date", isOn: $hasDueDate).tint(debtColor)
                    if hasDueDate { DatePicker("Due", selection: $dueDate, displayedComponents: .date) }
                }
                Section("Interest") {
                    Toggle("Has interest rate", isOn: $hasInterest).tint(debtColor)
                    if hasInterest {
                        HStack {
                            Text("Annual rate (%)"); Spacer()
                            TextField("e.g. 5", text: $interestText).multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                        }
                    }
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button { selectedIcon = icon; Haptics.selection() } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedIcon == icon ? debtColor : Color(uiColor: .tertiarySystemFill))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: icon).font(.system(size: 20))
                                        .foregroundColor(selectedIcon == icon ? .white : Color(uiColor: .secondaryLabel))
                                }
                            }.buttonStyle(.plain)
                        }
                    }.padding(.vertical, 4)
                }
                Section("Note") { TextField("Optional note", text: $note) }
            }
            .navigationTitle("Edit Debt")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundColor(isValid ? debtColor : Color(uiColor: .tertiaryLabel))
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")), amount > 0 else { return }
        var updated = debt
        updated.title = title.trimmingCharacters(in: .whitespaces)
        updated.person = person.trimmingCharacters(in: .whitespaces)
        updated.type = type
        updated.totalAmount = amount
        updated.dueDate = hasDueDate ? dueDate : nil
        updated.interestRate = hasInterest ? Double(interestText.replacingOccurrences(of: ",", with: ".")) : nil
        updated.note = note
        updated.icon = selectedIcon
        viewModel.updateDebt(updated)
        Haptics.success()
        dismiss()
    }
}
