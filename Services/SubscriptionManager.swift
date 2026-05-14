import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    enum ProductID {
        static let monthly = "com.chochesanchez.balanced.plus.monthly"
        static let yearly  = "com.chochesanchez.balanced.plus.yearly"
        static let all: [String] = [monthly, yearly]
    }

    enum RestoreState: Equatable {
        case idle
        case running
        case success(plus: Bool)
        case failure(String)
    }

    @Published private(set) var availableProducts: [Product] = []
    @Published private(set) var isPlus: Bool = false
    @Published private(set) var activeProductID: String? = nil
    @Published private(set) var expirationDate: Date? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastError: String? = nil
    @Published private(set) var restoreState: RestoreState = .idle
    @Published private(set) var lastEntitlementCheck: Date? = nil

    #if DEBUG
    @Published var debugForcePlus: Bool = false
    var effectiveIsPlus: Bool { isPlus || debugForcePlus }
    #else
    var effectiveIsPlus: Bool { isPlus }
    #endif

    private var transactionListenerTask: Task<Void, Never>?

    init() {
        transactionListenerTask = listenForTransactionUpdates()
        Task { await refresh() }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    func refresh() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: ProductID.all)
            availableProducts = products.sorted { lhs, rhs in
                (lhs.id == ProductID.monthly ? 0 : 1) < (rhs.id == ProductID.monthly ? 0 : 1)
            }
            lastError = nil
        } catch {
            availableProducts = []
            lastError = error.localizedDescription
            Log.plus.warning("loadProducts failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            var options: Set<Product.PurchaseOption> = []
            options.insert(.appAccountToken(AppIdentity.shared.appUserId))
            let result = try await product.purchase(options: options)
            switch result {
            case .success(let verification):
                if let tx = try? checkVerified(verification) {
                    await tx.finish()
                    await refreshEntitlements()
                    Log.plus.notice("Purchase verified \(tx.productID, privacy: .public)")
                    return true
                }
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            Log.plus.error("Purchase failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func restore() async {
        restoreState = .running
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            restoreState = .success(plus: isPlus)
            if isPlus {
                RatingManager.shared.registerPositiveEvent(.successfullyRestored)
            }
            Log.plus.notice("Restore completed; plus=\(self.isPlus)")
        } catch {
            lastError = error.localizedDescription
            restoreState = .failure(error.localizedDescription)
            Log.plus.error("Restore failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func clearRestoreState() {
        restoreState = .idle
    }

    func refreshEntitlements() async {
        var foundPlus = false
        var foundID: String? = nil
        var foundExpiry: Date? = nil
        for await result in StoreKit.Transaction.currentEntitlements {
            guard let tx = try? checkVerified(result) else { continue }
            if ProductID.all.contains(tx.productID) {
                foundPlus = true
                foundID = tx.productID
                foundExpiry = tx.expirationDate
            }
        }
        isPlus = foundPlus
        activeProductID = foundID
        expirationDate = foundExpiry
        lastEntitlementCheck = Date()
    }

    func openManageSubscriptions() async {
        guard let scene = await firstWindowScene() else { return }
        do {
            try await AppStore.showManageSubscriptions(in: scene)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw NSError(domain: "BalancePlus.Verification", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Unverified transaction"])
        }
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { continue }
                if let tx = try? await self.checkVerified(result) {
                    await tx.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    @MainActor
    private func firstWindowScene() async -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}
