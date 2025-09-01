//
//  DiscountCodeViewModel.swift
//  Disco
//
//  Created by Adrian Gri on 2025-08-21.
//

import Foundation
import SwiftUI

@MainActor
class DiscountCodeViewModel: ObservableObject {
  @Published var codes: [CodeInfo] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var showCopyToast = false

  private let service = DiscountCodeService.shared
  private let interstitialAdManager = InterstitialAdManager()

  // MARK: - Debug Settings
  /// Set to true to disable ads during testing
  private let isAdsDisabled = true  // Change to false for production

  func setMobileAdsStarted(_ started: Bool) {
    interstitialAdManager.setMobileAdsStarted(started)
  }

  func fetchCodes(for domain: String) {
    guard !domain.isEmpty else { return }

    isLoading = true
    errorMessage = nil
    codes = []

    // Show interstitial ad when loading starts
    showAdIfReady()

    Task {
      do {
        let fetchedCodes = try await service.fetchDiscountCodes(for: domain)
        codes = fetchedCodes
        print("✅ Fetched \(fetchedCodes.count) codes for \(domain)")
      } catch {
        errorMessage = error.localizedDescription
        print("❌ Failed to fetch codes: \(error)")
      }

      isLoading = false
    }
  }

  func clearCodes() {
    codes = []
    errorMessage = nil
    isLoading = false
  }

  func copyCode(_ code: String) {
    UIPasteboard.general.string = code
    print("📋 Copied code: \(code)")

    // Show toast notification
    showCopyToast = true

    // Hide toast after 2 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      self.showCopyToast = false
    }
  }

  private func showAdIfReady() {
    // Skip ads during testing if disabled
    guard !isAdsDisabled else {
      print("🚫 Ads disabled for testing")
      return
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      if self.interstitialAdManager.isAdReady {
        self.interstitialAdManager.showAd()
      } else {
        print("📢 Ad not ready, loading new ad for next time")
        self.interstitialAdManager.loadAd()
      }
    }
  }

  func preloadAd() {
    // This will only load if SDK is ready
    interstitialAdManager.loadAd()
  }
}
