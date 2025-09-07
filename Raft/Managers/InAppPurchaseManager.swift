//
//  InAppPurchaseManager.swift
//  Disco
//
//  Created on 2025-09-06.
//

import StoreKit
import SwiftUI

@MainActor
class InAppPurchaseManager: NSObject, ObservableObject {

  // MARK: - Published Properties
  @Published var isPremium = false
  @Published var isLoading = false
  @Published var purchaseError: String?
  @Published var products: [Product] = []

  // MARK: - Constants
  private let premiumProductID = "com.adriangri.disco.premium"  // Replace with your actual product ID
  private let premiumKey = "com.adriangri.disco.isPremium"

  // MARK: - Debug Settings
  #if DEBUG
    private let isDebugMode = true  // Set to false when you have real products configured
  #else
    private let isDebugMode = false
  #endif

  // MARK: - Initialization
  override init() {
    super.init()

    // Check if user already purchased premium
    isPremium = UserDefaults.standard.bool(forKey: premiumKey)

    // Start listening for transaction updates
    Task {
      await listenForTransactions()
    }
  }

  // MARK: - Product Loading
  func loadProducts() async {
    isLoading = true
    purchaseError = nil

    do {
      let productIDs = [premiumProductID]
      print("🔄 Attempting to load products with IDs: \(productIDs)")
      products = try await Product.products(for: productIDs)
      print("✅ Loaded \(products.count) products")

      if products.isEmpty {
        print("⚠️ No products found. This usually means:")
        print("  1. The product ID doesn't exist in App Store Connect")
        print("  2. The product isn't approved/ready for sale")
        print("  3. You're not signed in to a sandbox account (for testing)")
        purchaseError = "No products available. Please check your App Store Connect configuration."
      } else {
        for product in products {
          print("📦 Product found: \(product.id) - \(product.displayName) - \(product.displayPrice)")
        }
      }
    } catch {
      purchaseError = "Failed to load products: \(error.localizedDescription)"
      print("❌ Failed to load products: \(error)")
      print("📱 Error details: \(error)")
    }

    isLoading = false
  }

  // MARK: - Purchase Methods
  func purchasePremium() async {
    #if DEBUG
      if isDebugMode {
        print("🔧 Debug mode: Simulating premium purchase")
        isLoading = true

        // Simulate loading delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Grant premium access (already on main actor)
        isPremium = true
        UserDefaults.standard.set(true, forKey: premiumKey)
        isLoading = false

        print("✅ Debug: Premium purchase successful!")
        print("✅ Debug: isPremium = \(isPremium)")

        return
      }
    #endif

    guard let product = products.first(where: { $0.id == premiumProductID }) else {
      purchaseError = "Premium product not found. Make sure products are loaded first."
      print("❌ No premium product found in loaded products")
      return
    }

    isLoading = true
    purchaseError = nil

    do {
      let result = try await product.purchase()

      switch result {
      case .success(let verification):
        switch verification {
        case .verified(let transaction):
          // Successfully purchased and verified
          await handleSuccessfulPurchase(transaction)
        case .unverified(_, let error):
          purchaseError = "Purchase could not be verified: \(error.localizedDescription)"
        }
      case .userCancelled:
        print("User cancelled purchase")
      case .pending:
        print("Purchase is pending")
      @unknown default:
        purchaseError = "Unknown purchase result"
      }
    } catch {
      purchaseError = "Purchase failed: \(error.localizedDescription)"
      print("❌ Purchase failed: \(error)")
    }

    isLoading = false
  }

  func restorePurchases() async {
    isLoading = true
    purchaseError = nil

    do {
      try await AppStore.sync()
      print("✅ Purchases restored successfully")
    } catch {
      purchaseError = "Failed to restore purchases: \(error.localizedDescription)"
      print("❌ Failed to restore purchases: \(error)")
    }

    isLoading = false
  }

  // MARK: - Private Methods
  private func handleSuccessfulPurchase(_ transaction: StoreKit.Transaction) async {
    // Grant premium access
    isPremium = true
    UserDefaults.standard.set(true, forKey: premiumKey)

    // Finish the transaction
    await transaction.finish()

    print("✅ Premium purchase successful!")
  }

  private func listenForTransactions() async {
    // Listen for updates to transactions
    for await result in StoreKit.Transaction.updates {
      switch result {
      case .verified(let transaction):
        if transaction.productID == premiumProductID {
          await handleSuccessfulPurchase(transaction)
        }
      case .unverified(_, let error):
        print("❌ Unverified transaction: \(error)")
      }
    }
  }

  // MARK: - Helper Methods
  func getPremiumProduct() -> Product? {
    return products.first(where: { $0.id == premiumProductID })
  }

  func getPremiumPrice() -> String {
    #if DEBUG
      if isDebugMode {
        return "$1.99"  // Debug fallback price
      }
    #endif

    guard let product = getPremiumProduct() else {
      return "$1.99"  // Fallback price
    }
    return product.displayPrice
  }

  // MARK: - Debug Methods
  #if DEBUG
    func debugTogglePremium() {
      isPremium.toggle()
      UserDefaults.standard.set(isPremium, forKey: premiumKey)

      print("🔧 Debug: Premium status set to \(isPremium)")
    }

    func debugResetPremium() {
      isPremium = false
      UserDefaults.standard.set(false, forKey: premiumKey)
      print("🔧 Debug: Premium status reset to false")
    }
  #endif
}
