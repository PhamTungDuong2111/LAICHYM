import Foundation
import StoreKit

// MARK: - Product Identifiers
public struct VIPProduct {
    public static let monthly = "com.laichym.vip.monthly"
    public static let yearly = "com.laichym.vip.yearly"
    public static let lifetime = "com.laichym.vip.lifetime"
    
    public static let all = [monthly, yearly, lifetime]
}

// MARK: - StoreKit 2 Subscription Manager
public class StoreKitManager: ObservableObject {
    public static let shared = StoreKitManager()
    
    @Published public var products: [Product] = []
    @Published public var purchasedProductIDs = Set<String>()
    @Published public var isLoading: Bool = false
    @Published public var purchaseError: String? = nil
    
    private var updateListenerTask: Task<Void, Error>? = nil
    
    public var isVIP: Bool {
        return true
    }
    
    public init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
            await updatePurchasedStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    @MainActor
    public func requestProducts() async {
        isLoading = true
        do {
            let fetchedProducts = try await Product.products(for: VIPProduct.all)
            self.products = fetchedProducts.sorted(by: { $0.price < $1.price })
            self.isLoading = false
        } catch {
            self.purchaseError = "Không thể tải danh sách gói: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    public func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedStatus()
                await transaction.finish()
                UserSettings.shared.isVIP = true
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            await MainActor.run {
                self.purchaseError = error.localizedDescription
            }
            return false
        }
    }
    
    public func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedStatus()
    }
    
    @MainActor
    public func updatePurchasedStatus() async {
        var purchased = Set<String>()
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchased.insert(transaction.productID)
            } catch {
                print("Lỗi xác minh transaction: \(error)")
            }
        }
        self.purchasedProductIDs = purchased
        UserSettings.shared.isVIP = true
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedStatus()
                    await transaction.finish()
                } catch {
                    print("Lỗi transaction update: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "LAICHYM", code: 403, userInfo: [NSLocalizedDescriptionKey: "Giao dịch không hợp lệ"])
        case .verified(let safe):
            return safe
        }
    }
}
