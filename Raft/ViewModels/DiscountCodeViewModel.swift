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

  // State machine for loading process
  private enum LoadingState {
    case idle
    case loadingBoth  // Both API and timer running
    case waitingForTimer  // API done, waiting for 2-second timer
    case waitingForAPI  // Timer done (ad shown), waiting for API
    case complete  // Both API and timer completed
  }

  @Published private var loadingState: LoadingState = .idle

  // MARK: - Debug Settings
  /// Set to true to disable ads during testing
  private let isAdsDisabled = false  // Change to false for production

  func setMobileAdsStarted(_ started: Bool) {
    interstitialAdManager.setMobileAdsStarted(started)
  }

  func fetchCodes(for domain: String) {
    guard !domain.isEmpty else { return }

    // Initialize loading state
    loadingState = .loadingBoth
    isLoading = true
    errorMessage = nil
    codes = []

    // Start 1.5-second timer for minimum loading time
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      self.handleTimerCompleted()
    }

    // Start API call
    Task {
      do {
        let fetchedCodes = try await service.fetchDiscountCodes(for: domain)
        codes = fetchedCodes
        print("✅ Fetched \(fetchedCodes.count) codes for \(domain)")
      } catch {
        errorMessage = error.localizedDescription
        print("❌ Failed to fetch codes: \(error)")
      }

      handleAPICompleted()
    }
  }

  private func handleTimerCompleted() {
    // Always show ad when timer completes, regardless of API status
    showAdIfReady()
    
    switch loadingState {
    case .loadingBoth:
      // API still running, timer done - wait for API
      loadingState = .waitingForAPI
    case .waitingForTimer:
      // API already done, timer just finished - complete after delay
      loadingState = .complete
      finishLoadingAfterDelay()
    default:
      break
    }
  }

  private func handleAPICompleted() {
    switch loadingState {
    case .loadingBoth:
      // Timer still running, API done - wait for timer (ad will show then)
      loadingState = .waitingForTimer
    case .waitingForAPI:
      // Timer already done (ad already shown), API just finished - complete after delay
      loadingState = .complete
      finishLoadingAfterDelay()
    default:
      break
    }
  }

  private func finishLoadingAfterDelay() {
    // Wait a bit for the ad to display before showing codes
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.finishLoading()
    }
  }

  private func finishLoading() {
    isLoading = false
    loadingState = .idle
  }

  func clearCodes() {
    codes = []
    errorMessage = nil
    isLoading = false
    loadingState = .idle
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
