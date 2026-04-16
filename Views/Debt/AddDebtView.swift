import SwiftUI

// MARK: - Add Debt View
struct AddDebtView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var person = ""
    @State private var type: DebtType = .iOwe
    @State private var amountText = ""
    @State private var hasDueDate = false
    @State private var dueDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var hasInterest = false
    @State private var interestText = ""
    @State private var note = ""
    @State private var selectedIcon = "creditcard.fill"
    @FocusState private var focusedField: Field?

    enum Field { case title, person, amount, interest, note }

    private let icons = [
        "creditcard.fill", "person.fill", "house.fill",
        "car.fill", "bag.fill", "banknote.fill",
        "stethoscope", "graduationcap.fill", "wrench.fill", "cart.fill"
    ]
    private let debtColor = Color(hex: "FF3B30")

    private var parsedAmount: Double? {
        let cleaned = amountText.replacingOccurrences(of: ",", with: ".")
        guard let v = Double(cleaned), v > 0 else { return nil }
        return v
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && parsedAmount != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Debt Details") {
                    HStack {
                        Text("Title")
                        Spacer()
                        TextField("e.g. Rent Loan", text: $title)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .title)
                    }
                    HStack {
                        Text("Person / Entity")
                        Spacer()
                        TextField("e.g. John, Bank", text: $person)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .person)
                    }
                    Picker("Type", selection: $type) {
                        ForEach(DebtType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amountText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                    }
                }

                Section("Due Date") {
                    Toggle("Has due date", isOn: $hasDueDate)
                        .tint(debtColor)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Interest") {
                    Toggle("Has interest rate", isOn: $hasInterest)
                        .tint(debtColor)
                    if hasInterest {
                        HStack {
                            Text("Annual rate (%)")
                            Spacer()
                            TextField("e.g. 5", text: $interestText)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .interest)
                        }
                    }
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                Haptics.selection()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedIcon == icon ? debtColor : Color(uiColor: .tertiarySystemFill))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedIcon == icon ? .white : Color(uiColor: .secondaryLabel))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Note") {
                    TextField("Optional note", text: $note)
                        .focused($focusedField, equals: .note)
                }
            }
            .navigationTitle("New Debt")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { save() }
                        .fontWeight(.semibold)
                        .foregroundColor(isValid ? debtColor : Color(uiColor: .tertiaryLabel))
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        guard let amount = parsedAmount else { return }
        let interest = hasInterest ? Double(interestText.replacingOccurrences(of: ",", with: ".")) : nil
        let debt = Debt(
            title: title.trimmingCharacters(in: .whitespaces),
            person: person.trimmingCharacters(in: .whitespaces),
            totalAmount: amount,
            type: type,
            dueDate: hasDueDate ? dueDate : nil,
            icon: selectedIcon,
            note: note,
            interestRate: interest
        )
        viewModel.addDebt(debt)
        Haptics.success()
        dismiss()
    }
}
