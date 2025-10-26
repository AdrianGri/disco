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

  // Premium status - will be injected from parent view
  var isPremium: Bool = false

  // Task for fetching codes - can be cancelled
  private var fetchTask: Task<Void, Never>?

  // State machine for loading process
  private enum LoadingState {
    case idle
    case loadingBoth  // Both API and timer running
    case waitingForTimer  // API done, waiting for 2-second timer
    case waitingForAPI  // Timer done (ad shown), waiting for API
    case complete  // Both API and timer completed
  }

  @Published private var loadingState: LoadingState = .idle

  func setMobileAdsStarted(_ started: Bool) {
    interstitialAdManager.setMobileAdsStarted(started)
  }

  func fetchCodes(for domain: String) {
    guard !domain.isEmpty else { return }

    // Cancel any existing fetch task
    fetchTask?.cancel()

    // Initialize loading state
    loadingState = .loadingBoth
    isLoading = true
    errorMessage = nil
    codes = []

    // Start 1.5-second timer for minimum loading time (skip for premium users)
    let delay = isPremium ? 0.0 : 1.5
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      self.handleTimerCompleted()
    }

    // Start API call
    fetchTask = Task {
      do {
        let fetchedCodes = try await service.fetchDiscountCodes(for: domain)
        
        // Check if task was cancelled before updating state
        guard !Task.isCancelled else {
          print("⚠️ Fetch task was cancelled for \(domain)")
          return
        }
        
        codes = fetchedCodes
        print("✅ Fetched \(fetchedCodes.count) codes for \(domain)")
      } catch {
        // Check if task was cancelled before updating error
        guard !Task.isCancelled else {
          print("⚠️ Fetch task was cancelled for \(domain)")
          return
        }
        
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
    // Cancel any ongoing fetch task
    fetchTask?.cancel()
    fetchTask = nil
    
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
    // Skip ads if user has premium
    guard !isPremium else {
      print("✨ Premium user - skipping ads")
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
