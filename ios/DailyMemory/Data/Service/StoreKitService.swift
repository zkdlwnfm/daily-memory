import Foundation
import StoreKit

/// StoreKit 2 service for managing Premium subscription
@MainActor
final class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    // Product IDs
    static let monthlyID = "com.effortmoney.dailymemory.premium.monthly"
    static let yearlyID = "com.effortmoney.dailymemory.premium.yearly"

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyID }
    }

    private var updateTask: Task<Void, Never>?

    private init() {
        updateTask = Task { await listenForTransactions() }
        Task { await loadProducts() }
        Task { await updatePurchasedProducts() }
    }

    deinit {
        updateTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: [Self.monthlyID, Self.yearlyID])
                .sorted { $0.price < $1.price }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        error = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedProducts()
                await syncPremiumStatus(isPremium: true)
                isLoading = false
                return true

            case .userCancelled:
                isLoading = false
                return false

            case .pending:
                isLoading = false
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        try? await AppStore.sync()
        await updatePurchasedProducts()
        isLoading = false
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await updatePurchasedProducts()
                await transaction.finish()
            }
        }
    }

    // MARK: - Update State

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = purchased

        // Sync with backend
        await syncPremiumStatus(isPremium: !purchased.isEmpty)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    // MARK: - Backend Sync

    private func syncPremiumStatus(isPremium: Bool) async {
        guard let uid = AuthService.shared.currentUserId else { return }

        // Update Firestore user profile
        if case .signedIn(var profile) = AuthService.shared.authState {
            profile.isPremium = isPremium
            try? await FirestoreService.shared.saveUserProfile(profile)
        }
    }
}

// MARK: - Errors

enum StoreError: LocalizedError {
    case verificationFailed
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed: return "Purchase verification failed"
        case .purchaseFailed: return "Purchase failed"
        }
    }
}
