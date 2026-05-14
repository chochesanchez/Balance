import SwiftUI
import UniformTypeIdentifiers

struct BackupSettingsView: View {
    @ObservedObject var viewModel: BalancedViewModel
    @State private var resetHoldProgress: Double = 0
    @State private var resetTask: Task<Void, Never>?
    @State private var showResetConfirm = false
    @State private var showImportPicker = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var toast: String?

    var body: some View {
        List {
            Section("iCloud Sync") {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.iCloudSyncEnabled ? "checkmark.icloud.fill" : "xmark.icloud")
                        .foregroundColor(viewModel.iCloudSyncEnabled ? Theme.Colors.income : Color(uiColor: .secondaryLabel))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.iCloudSyncEnabled ? "Synced with iCloud" : "iCloud unavailable")
                            .font(.system(size: 15, weight: .semibold))
                        Text(lastSyncText)
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
                Button {
                    viewModel.backupNow()
                    toast = "Backup queued — saving to iCloud."
                } label: {
                    Label("Back up now", systemImage: "arrow.up.to.line")
                }
                .disabled(!viewModel.iCloudSyncEnabled)
                Button {
                    viewModel.reloadFromCloud()
                    toast = "Restored latest iCloud data."
                } label: {
                    Label("Restore from iCloud", systemImage: "arrow.down.to.line")
                }
                .disabled(!viewModel.iCloudSyncEnabled)
            }

            Section {
                Button {
                    if let url = exportSnapshotURL() {
                        exportURL = url
                        showExportSheet = true
                    }
                } label: {
                    Label("Export data", systemImage: "square.and.arrow.up")
                }
                Button {
                    showImportPicker = true
                } label: {
                    Label("Import data", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("Export & Import")
            } footer: {
                Text("Export saves a single JSON snapshot of your data. Import will replace your current data after you confirm.")
            }

            Section("Reset") {
                Button {
                    viewModel.resetOnboarding()
                    toast = "Onboarding reset."
                } label: {
                    Label("Reset onboarding", systemImage: "arrow.counterclockwise")
                }
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Reset all data", systemImage: "trash")
                }
            }

            if !viewModel.adjustments.isEmpty {
                Section("Adjustment Log") {
                    ForEach(viewModel.adjustments.sorted(by: { $0.date > $1.date }).prefix(20)) { adj in
                        adjustmentRow(adj)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Data & Backup")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset All Data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Hold to delete", role: .destructive) {
                showResetConfirm = false
                startHoldToReset()
            }
        } message: {
            Text("This cannot be undone unless you have an iCloud backup. After tapping Hold to delete, press and hold the next prompt for 3 seconds.")
        }
        .overlay(alignment: .center) {
            if resetTask != nil {
                holdOverlay
            }
            if let toast {
                toastView(toast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { self.toast = nil }
                        }
                    }
            }
        }
        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private var lastSyncText: String {
        guard let date = viewModel.lastSyncDate else { return "No recent backup" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return "Last backup \(f.localizedString(for: date, relativeTo: Date()))"
    }

    @ViewBuilder
    private func adjustmentRow(_ adj: BalanceAdjustment) -> some View {
        HStack(spacing: 12) {
            Image(systemName: adj.kind.iconName)
                .foregroundColor(adj.kind.tint)
                .frame(width: 32, height: 32)
                .background(adj.kind.tint.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(adj.kind.displayName)
                    .font(.system(size: 14, weight: .semibold))
                Text(adj.entityName)
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                Text("\(formatCurrency(adj.previousAmount, currency: viewModel.appState.selectedCurrency)) → \(formatCurrency(adj.newAmount, currency: viewModel.appState.selectedCurrency))")
                    .font(.system(size: 11))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                if let note = adj.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 11))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
            Spacer()
            Text(adj.date, style: .date)
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var holdOverlay: some View {
        VStack(spacing: 14) {
            Text("Hold to delete (3 seconds)")
                .font(.system(size: 15, weight: .semibold))
            ZStack(alignment: .leading) {
                Capsule().fill(Color(uiColor: .tertiarySystemFill)).frame(height: 14)
                Capsule().fill(Theme.Colors.expense).frame(width: 220 * resetHoldProgress, height: 14)
            }
            .frame(width: 220)
            Button("Cancel") {
                resetTask?.cancel()
                resetTask = nil
                resetHoldProgress = 0
            }
            .font(.system(size: 13, weight: .medium))
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(radius: 12)
    }

    private func toastView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.thinMaterial)
            .cornerRadius(20)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func startHoldToReset() {
        resetHoldProgress = 0
        resetTask = Task {
            let totalSteps = 30
            for i in 1...totalSteps {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 100_000_000)
                resetHoldProgress = Double(i) / Double(totalSteps)
            }
            if !Task.isCancelled {
                viewModel.resetAllData()
                Haptics.success()
                toast = "All data deleted."
            }
            resetTask = nil
            resetHoldProgress = 0
        }
    }

    private func exportSnapshotURL() -> URL? {
        struct Snapshot: Codable {
            let accounts: [Account]
            let categories: [Category]
            let transactions: [Transaction]
            let goals: [Goal]
            let recurringTransactions: [RecurringTransaction]
            let debts: [Debt]
            let adjustments: [BalanceAdjustment]
            let userProfile: UserProfile
            let appState: AppState
            let exportedAt: Date
        }
        let snap = Snapshot(
            accounts: viewModel.accounts,
            categories: viewModel.categories,
            transactions: viewModel.transactions,
            goals: viewModel.goals,
            recurringTransactions: viewModel.recurringTransactions,
            debts: viewModel.debts,
            adjustments: viewModel.adjustments,
            userProfile: viewModel.userProfile,
            appState: viewModel.appState,
            exportedAt: Date()
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snap) else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmm"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("balance-export-\(f.string(from: Date())).json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            Log.app.error("Export failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let err):
            toast = "Import failed: \(err.localizedDescription)"
        case .success(let url):
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                struct Snapshot: Codable {
                    var accounts: [Account] = []
                    var categories: [Category] = []
                    var transactions: [Transaction] = []
                    var goals: [Goal] = []
                    var recurringTransactions: [RecurringTransaction] = []
                    var debts: [Debt] = []
                    var adjustments: [BalanceAdjustment] = []
                    var userProfile: UserProfile = UserProfile()
                    var appState: AppState = AppState()
                }
                let snap = try JSONDecoder().decode(Snapshot.self, from: data)
                viewModel.accounts = snap.accounts
                viewModel.categories = snap.categories
                viewModel.transactions = snap.transactions
                viewModel.goals = snap.goals
                viewModel.recurringTransactions = snap.recurringTransactions
                viewModel.debts = snap.debts
                viewModel.adjustments = snap.adjustments
                viewModel.userProfile = snap.userProfile
                viewModel.appState = snap.appState
                viewModel.backupNow()
                viewModel.refreshWeeklyHistory()
                toast = "Imported \(snap.transactions.count) transactions."
            } catch {
                toast = "Could not read file: \(error.localizedDescription)"
            }
        }
    }
}

private extension BalanceAdjustment.Kind {
    var displayName: String {
        switch self {
        case .accountBalanceCorrection: return "Account balance corrected"
        case .potSavedAmountCorrection: return "Pot saved amount corrected"
        case .accountDeletionRemovedBalance: return "Account balance removed on delete"
        case .accountClosureTransfer: return "Account closed with transfer"
        case .demoDataRemoved: return "Sample data removed"
        }
    }
    var iconName: String {
        switch self {
        case .accountBalanceCorrection: return "pencil"
        case .potSavedAmountCorrection: return "pencil"
        case .accountDeletionRemovedBalance: return "trash"
        case .accountClosureTransfer: return "arrow.left.arrow.right"
        case .demoDataRemoved: return "sparkles"
        }
    }
    var tint: Color {
        switch self {
        case .accountBalanceCorrection, .potSavedAmountCorrection: return Theme.Colors.primary
        case .accountDeletionRemovedBalance: return Theme.Colors.expense
        case .accountClosureTransfer: return Color(uiColor: .systemGray)
        case .demoDataRemoved: return Theme.Colors.recurring
        }
    }
}

