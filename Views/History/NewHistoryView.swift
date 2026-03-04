import SwiftUI

// MARK: - New History View
/// Transaction history with improved filters and transaction detail
struct NewHistoryView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var searchText = ""
    @State private var selectedFilters: Set<TransactionType> = []
    @State private var showRecurringOnly = false
    @State private var showingDatePicker = false
    @State private var showingSearch = false
    @State private var showingFiltersSheet = false
    @State private var selectedDate: Date? = nil
    @State private var selectedTransaction: Transaction?
    
    // Advanced filters
    @State private var selectedCategories: Set<UUID> = []
    @State private var selectedAccounts: Set<UUID> = []
    
    private var filteredTransactions: [Transaction] {
        var transactions = viewModel.transactions
        
        // Filter by type
        if !selectedFilters.isEmpty {
            transactions = transactions.filter { selectedFilters.contains($0.type) }
        }
        
        // Filter recurring only
        if showRecurringOnly {
            transactions = transactions.filter { $0.recurringId != nil }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            transactions = transactions.filter { transaction in
                transaction.title.localizedCaseInsensitiveContains(searchText) ||
                transaction.note.localizedCaseInsensitiveContains(searchText) ||
                viewModel.getCategory(by: transaction.categoryId)?.name.localizedCaseInsensitiveContains(searchText) == true ||
                viewModel.getAccount(by: transaction.accountId)?.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Filter by date
        if let first = selectedDate {
            let startOfDay = Calendar.current.startOfDay(for: first)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? first
            transactions = transactions.filter { $0.date >= startOfDay && $0.date < endOfDay }
        }
        
        // Filter by categories
        if !selectedCategories.isEmpty {
            transactions = transactions.filter { tx in
                if let catId = tx.categoryId {
                    return selectedCategories.contains(catId)
                }
                return false
            }
        }
        
        // Filter by accounts
        if !selectedAccounts.isEmpty {
            transactions = transactions.filter { selectedAccounts.contains($0.accountId) }
        }
        
        return transactions.sorted { $0.date > $1.date }
    }
    
    private var groupedTransactions: [(String, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            formatDateHeader(transaction.date)
        }
        return grouped.sorted { group1, group2 in
            let date1 = group1.value.first?.date ?? .distantPast
            let date2 = group2.value.first?.date ?? .distantPast
            return date1 > date2
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            if showingSearch {
                SearchBar(text: $searchText, onClose: {
                    searchText = ""
                    showingSearch = false
                })
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
            }
            
            // Date Filter Badge
            if selectedDate != nil {
                DateFilterBadge(
                    selectedDate: selectedDate,
                    onClear: { selectedDate = nil }
                )
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
            }
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    FilterPill(
                        title: "All",
                        isSelected: selectedFilters.isEmpty && !showRecurringOnly,
                        selectedColor: Color.gray,
                        action: {
                            selectedFilters.removeAll()
                            showRecurringOnly = false
                        }
                    )
                    
                    FilterPill(
                        title: "Income",
                        icon: "arrow.down.circle.fill",
                        isSelected: selectedFilters.contains(.income),
                        selectedColor: Theme.Colors.income,
                        action: { toggleFilter(.income) }
                    )
                    
                    FilterPill(
                        title: "Expense",
                        icon: "arrow.up.circle.fill",
                        isSelected: selectedFilters.contains(.expense),
                        selectedColor: Theme.Colors.expense,
                        action: { toggleFilter(.expense) }
                    )
                    
                    FilterPill(
                        title: "Transfer",
                        icon: "arrow.left.arrow.right.circle.fill",
                        isSelected: selectedFilters.contains(.transfer),
                        selectedColor: Theme.Colors.transfer,
                        action: { toggleFilter(.transfer) }
                    )
                    
                    FilterPill(
                        title: "Recurring",
                        icon: "repeat.circle.fill",
                        isSelected: showRecurringOnly,
                        selectedColor: Theme.Colors.recurring,
                        action: {
                            showRecurringOnly.toggle()
                            Haptics.selection()
                        }
                    )
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
            
            Divider()
            
            // Transactions List
            if filteredTransactions.isEmpty {
                EmptyTransactionsView()
            } else {
                List {
                    ForEach(groupedTransactions, id: \.0) { date, transactions in
                        Section(header: Text(date).font(Theme.Typography.subheadline)) {
                            ForEach(transactions) { transaction in
                                HistoryTransactionRow(
                                    transaction: transaction,
                                    account: viewModel.getAccount(by: transaction.accountId),
                                    category: viewModel.getCategory(by: transaction.categoryId),
                                    currency: viewModel.appState.selectedCurrency
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTransaction = transaction
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteTransaction(transaction)
                                        Haptics.medium()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    // Search
                    Button(action: {
                        showingSearch.toggle()
                        Haptics.light()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(showingSearch ? Theme.Colors.primary : Theme.Colors.primaryText)
                    }
                    
                    // Calendar
                    Button(action: {
                        showingDatePicker = true
                        Haptics.light()
                    }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundColor(selectedDate != nil ? Theme.Colors.primary : Theme.Colors.primaryText)
                    }
                    
                    // More Filters
                    Button(action: {
                        showingFiltersSheet = true
                        Haptics.light()
                    }) {
                        Image(systemName: hasActiveAdvancedFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18))
                            .foregroundColor(hasActiveAdvancedFilters ? Theme.Colors.primary : Theme.Colors.primaryText)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            ImprovedDatePickerSheet(
                selectedDate: $selectedDate,
                isPresented: $showingDatePicker
            )
        }
        .sheet(isPresented: $showingFiltersSheet) {
            AdvancedFiltersSheet(
                viewModel: viewModel,
                selectedCategories: $selectedCategories,
                selectedAccounts: $selectedAccounts,
                isPresented: $showingFiltersSheet
            )
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(
                viewModel: viewModel,
                transaction: transaction
            )
        }
    }
    
    private var hasActiveAdvancedFilters: Bool {
        !selectedCategories.isEmpty || !selectedAccounts.isEmpty
    }
    
    private func toggleFilter(_ type: TransactionType) {
        if selectedFilters.contains(type) {
            selectedFilters.remove(type)
        } else {
            selectedFilters.insert(type)
        }
        Haptics.selection()
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.secondaryText)
            
            TextField("Search transactions", text: $text)
                .font(Theme.Typography.body)
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

// MARK: - Date Filter Badge
struct DateFilterBadge: View {
    let selectedDate: Date?
    let onClear: () -> Void
    
    private var dateText: String {
        guard let date = selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.primary)
            
            Text(dateText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
            
            Spacer()
            
            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.Colors.primary.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? selectedColor : Color(uiColor: .tertiarySystemFill))
            .foregroundColor(isSelected ? .white : Color(uiColor: .label))
            .cornerRadius(20)
        }
    }
}

// MARK: - History Transaction Row (with original icon colors)
struct HistoryTransactionRow: View {
    let transaction: Transaction
    let account: Account?
    let category: Category?
    let currency: String
    
    var body: some View {
        HStack(spacing: 12) {
            TransactionIconBadge(category: category, account: account, size: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title.isEmpty ? (category?.name ?? transaction.type.rawValue) : transaction.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(uiColor: .label))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(account?.name ?? "")
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    if transaction.recurringId != nil {
                        Image(systemName: "repeat")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.recurring)
                    }
                }
                .font(.system(size: 12))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(amountColor)
                
                Text(formatTime(transaction.date))
                    .font(.system(size: 11))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
        }
        .padding(.vertical, 4)
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .expense: return Theme.Colors.expense
        case .income: return Theme.Colors.income
        case .transfer: return Theme.Colors.transfer
        }
    }
    
    private var formatAmount: String {
        let prefix = transaction.type == .income ? "+" : transaction.type == .expense ? "-" : ""
        return "\(prefix)\(formatCurrency(transaction.amount, currency: currency))"
    }
}

// MARK: - Transaction Detail View
struct TransactionDetailView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let transaction: Transaction
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showDeleteConfirm = false
    
    @State private var editedTitle: String = ""
    @State private var editedNote: String = ""
    @State private var editedAmount: String = ""
    @State private var editedDate: Date = Date()
    @State private var editedType: TransactionType = .expense
    @State private var editedAccountId: UUID?
    @State private var editedToAccountId: UUID?
    @State private var editedCategoryId: UUID?
    
    private var liveTransaction: Transaction {
        viewModel.transactions.first(where: { $0.id == transaction.id }) ?? transaction
    }

    private var account: Account? {
        viewModel.getAccount(by: isEditing ? (editedAccountId ?? transaction.accountId) : liveTransaction.accountId)
    }
    private var toAccount: Account? {
        guard let id = isEditing ? editedToAccountId : liveTransaction.toAccountId else { return nil }
        return viewModel.getAccount(by: id)
    }
    private var category: Category? {
        viewModel.getCategory(by: isEditing ? editedCategoryId : liveTransaction.categoryId)
    }
    private var displayType: TransactionType { isEditing ? editedType : liveTransaction.type }
    
    private var typeColor: Color {
        switch displayType {
        case .income: return Theme.Colors.income
        case .expense: return Theme.Colors.expense
        case .transfer: return Theme.Colors.transfer
        }
    }
    
    private var availableCategories: [Category] {
        editedType == .income ? viewModel.incomeCategories : viewModel.expenseCategories
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerSection
                    
                    if isEditing {
                        editContent
                    } else {
                        viewContent
                    }
                    
                    if !isEditing {
                        deleteButton
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit" : "Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Cancel" : "Close") {
                        if isEditing {
                            withAnimation(.snappy) { isEditing = false }
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing { saveChanges() } else { startEditing() }
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Transaction", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    viewModel.deleteTransaction(transaction)
                    Haptics.medium()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            TransactionIconBadge(category: category, account: account, size: 64)
            
            if isEditing {
                TextField("0", text: $editedAmount)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(uiColor: .label))
            } else {
                Text(formatSignedAmount)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(typeColor)
            }
            
            Text(displayType.rawValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(typeColor.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(typeColor.opacity(0.1))
                .cornerRadius(6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }
    
    // MARK: - View Mode
    private var viewContent: some View {
        VStack(spacing: 0) {
            DetailRow(label: "Title", value: transaction.title.isEmpty ? "-" : transaction.title)
            Divider().padding(.leading, 16)
            DetailRow(label: "Category", value: category?.name ?? "-", icon: category?.icon, iconColor: category?.colorValue)
            Divider().padding(.leading, 16)
            DetailRow(label: "Account", value: account?.name ?? "-", icon: account?.icon, iconColor: account?.colorValue)
            if transaction.type == .transfer, let to = toAccount {
                Divider().padding(.leading, 16)
                DetailRow(label: "To Account", value: to.name, icon: to.icon, iconColor: to.colorValue)
            }
            Divider().padding(.leading, 16)
            DetailRow(label: "Date", value: formatFullDate(transaction.date))
            if !transaction.note.isEmpty {
                Divider().padding(.leading, 16)
                DetailRow(label: "Note", value: transaction.note)
            }
            if transaction.recurringId != nil {
                Divider().padding(.leading, 16)
                HStack {
                    Text("Recurring")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 12))
                        Text("Yes")
                            .font(.system(size: 15))
                    }
                    .foregroundColor(Theme.Colors.recurring)
                }
                .padding(Theme.Spacing.md)
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Edit Mode
    private var editContent: some View {
        VStack(spacing: 14) {
            // Type selector
            VStack(spacing: 0) {
                HStack {
                    Text("Type")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
                
                HStack(spacing: 8) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        let color: Color = type == .income ? Theme.Colors.income : type == .expense ? Theme.Colors.expense : Theme.Colors.transfer
                        Button(action: {
                            withAnimation(.snappy) { editedType = type }
                            if type == .transfer { editedCategoryId = nil }
                            Haptics.selection()
                        }) {
                            Text(type.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(editedType == type ? color : Color(uiColor: .tertiarySystemFill))
                                .foregroundColor(editedType == type ? .white : Color(uiColor: .label))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(14)
            .padding(.horizontal, 16)
            
            // Details card
            VStack(spacing: 0) {
                DetailEditRow(label: "Title", text: $editedTitle)
                Divider().padding(.leading, 16)
                DetailEditRow(label: "Note", text: $editedNote)
                Divider().padding(.leading, 16)
                DatePicker("Date", selection: $editedDate, displayedComponents: [.date, .hourAndMinute])
                    .font(.system(size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(14)
            .padding(.horizontal, 16)
            
            // Account picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Account")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.accounts) { acc in
                            Button(action: {
                                editedAccountId = acc.id
                                Haptics.selection()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: acc.icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(editedAccountId == acc.id ? .white : acc.colorValue)
                                    Text(acc.name)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(editedAccountId == acc.id ? Theme.Colors.primary : Color(uiColor: .tertiarySystemFill))
                                .foregroundColor(editedAccountId == acc.id ? .white : Color(uiColor: .label))
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                if editedType == .transfer {
                    Text("To Account")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.accounts.filter { $0.id != editedAccountId }) { acc in
                                Button(action: {
                                    editedToAccountId = acc.id
                                    Haptics.selection()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: acc.icon)
                                            .font(.system(size: 12))
                                            .foregroundColor(editedToAccountId == acc.id ? .white : acc.colorValue)
                                        Text(acc.name)
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(editedToAccountId == acc.id ? Theme.Colors.transfer : Color(uiColor: .tertiarySystemFill))
                                    .foregroundColor(editedToAccountId == acc.id ? .white : Color(uiColor: .label))
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            
            // Category picker
            if editedType != .transfer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Category")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableCategories) { cat in
                                Button(action: {
                                    editedCategoryId = cat.id
                                    Haptics.selection()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 12))
                                            .foregroundColor(editedCategoryId == cat.id ? .white : cat.colorValue)
                                        Text(cat.name)
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(editedCategoryId == cat.id ? cat.colorValue : Color(uiColor: .tertiarySystemFill))
                                    .foregroundColor(editedCategoryId == cat.id ? .white : Color(uiColor: .label))
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Button
    private var deleteButton: some View {
        Button(action: { showDeleteConfirm = true }) {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                Text("Delete Transaction")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(Theme.Colors.expense)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.Colors.expense.opacity(0.08))
            .cornerRadius(14)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
    private var formatSignedAmount: String {
        let prefix = transaction.type == .income ? "+" : transaction.type == .expense ? "-" : ""
        return "\(prefix)\(formatCurrency(transaction.amount, currency: viewModel.appState.selectedCurrency))"
    }
    
    private func startEditing() {
        let tx = liveTransaction
        editedTitle = tx.title
        editedNote = tx.note
        editedAmount = String(tx.amount)
        editedDate = tx.date
        editedType = tx.type
        editedAccountId = tx.accountId
        editedToAccountId = tx.toAccountId
        editedCategoryId = tx.categoryId
        withAnimation(.snappy) { isEditing = true }
    }
    
    private func saveChanges() {
        var updated = transaction
        updated.title = editedTitle
        updated.note = editedNote
        updated.type = editedType
        updated.accountId = editedAccountId ?? transaction.accountId
        updated.toAccountId = editedType == .transfer ? editedToAccountId : nil
        updated.categoryId = editedType == .transfer ? nil : editedCategoryId
        if let amount = Double(editedAmount) { updated.amount = amount }
        updated.date = editedDate
        viewModel.updateTransaction(updated)
        withAnimation(.snappy) { isEditing = false }
        Haptics.success()
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .short
        return df.string(from: date)
    }
}

// MARK: - Transaction Icon with Account Badge
struct TransactionIconBadge: View {
    let category: Category?
    let account: Account?
    var size: CGFloat = 44
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main category icon
            ZStack {
                Circle()
                    .fill((category?.colorValue ?? account?.colorValue ?? Color(uiColor: .secondaryLabel)).opacity(0.15))
                    .frame(width: size, height: size)
                
                Image(systemName: category?.icon ?? account?.icon ?? "dollarsign.circle")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(category?.colorValue ?? account?.colorValue ?? Color(uiColor: .secondaryLabel))
            }
            
            // Account badge
            if let acc = account, category != nil {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .systemBackground))
                        .frame(width: size * 0.4, height: size * 0.4)
                    Circle()
                        .fill(acc.colorValue.opacity(0.2))
                        .frame(width: size * 0.35, height: size * 0.35)
                    Image(systemName: acc.icon)
                        .font(.system(size: size * 0.15))
                        .foregroundColor(acc.colorValue)
                }
                .offset(x: size * 0.08, y: size * 0.08)
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var iconColor: Color? = nil
    
    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Spacer()
            
            HStack(spacing: Theme.Spacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor ?? Theme.Colors.secondaryText)
                }
                Text(value)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
            }
        }
        .padding(Theme.Spacing.md)
    }
}

struct DetailEditRow: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.secondaryText)
            
            TextField(label, text: $text)
                .font(Theme.Typography.body)
                .multilineTextAlignment(.trailing)
        }
        .padding(Theme.Spacing.md)
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let subvalue: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            Text(subvalue)
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.small)
    }
}

// MARK: - Date Picker Sheet
struct ImprovedDatePickerSheet: View {
    @Binding var selectedDate: Date?
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var pickerDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker("", selection: $pickerDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Theme.Colors.primary)
                    .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Select")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    
                    HStack(spacing: 8) {
                        QuickDateButton(title: "Today") { pickerDate = Date() }
                        QuickDateButton(title: "Yesterday") {
                            pickerDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                        }
                        QuickDateButton(title: "Last Week") {
                            pickerDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        selectedDate = nil
                        dismiss()
                    }) {
                        Text("Clear")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(uiColor: .label))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(uiColor: .tertiarySystemFill))
                            .cornerRadius(14)
                    }
                    
                    Button(action: {
                        selectedDate = pickerDate
                        dismiss()
                    }) {
                        Text("Apply")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.Colors.primary)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if let date = selectedDate { pickerDate = date }
        }
    }
}

struct QuickDateButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.caption)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Colors.primary.opacity(0.1))
                .foregroundColor(Theme.Colors.primary)
                .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

// MARK: - Advanced Filters Sheet
struct AdvancedFiltersSheet: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Binding var selectedCategories: Set<UUID>
    @Binding var selectedAccounts: Set<UUID>
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Accounts") {
                    ForEach(viewModel.accounts) { account in
                        Button(action: {
                            if selectedAccounts.contains(account.id) {
                                selectedAccounts.remove(account.id)
                            } else {
                                selectedAccounts.insert(account.id)
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: account.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(account.colorValue)
                                    .frame(width: 28)
                                Text(account.name)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(uiColor: .label))
                                Spacer()
                                if selectedAccounts.contains(account.id) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Theme.Colors.primary)
                                }
                            }
                        }
                    }
                }
                
                Section("Categories") {
                    ForEach(viewModel.categories) { category in
                        Button(action: {
                            if selectedCategories.contains(category.id) {
                                selectedCategories.remove(category.id)
                            } else {
                                selectedCategories.insert(category.id)
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(category.colorValue)
                                    .frame(width: 28)
                                Text(category.name)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(uiColor: .label))
                                Spacer()
                                if selectedCategories.contains(category.id) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Theme.Colors.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategories.removeAll()
                        selectedAccounts.removeAll()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Empty Transactions View
struct EmptyTransactionsView: View {
    var body: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 60)
            
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
            
            Text("No transactions found")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(uiColor: .label))
            
            Text("Try adjusting your filters\nor record a new transaction")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
}

// MARK: - Helpers
private func formatDateHeader(_ date: Date) -> String {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
        return "Today"
    } else if calendar.isDateInYesterday(date) {
        return "Yesterday"
    } else {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        NewHistoryView(viewModel: BalanceViewModel())
    }
}
