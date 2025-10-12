//
//  InterstitialAdManager.swift
//  Disco
//
//  Created by Adrian Gri on 2025-08-21.
//

import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI

class InterstitialAdManager: NSObject, ObservableObject {
  // Test ad unit ID for development - replace with your actual ad unit ID before publishing
  // For production, you should replace this with your actual AdMob ad unit ID
  // private let adUnitID = "ca-app-pub-3940256099942544/4411468910"

  // Actual ad unit ID
  private let adUnitID = "ca-app-pub-2372535455386330/6074269316"

  @Published var interstitialAd: InterstitialAd?
  @Published var isLoading = false
  @Published var isAdReady = false

  private var isMobileAdsStarted = false

  override init() {
    super.init()
    // Don't load ad immediately - wait for SDK to be ready
  }

  func setMobileAdsStarted(_ started: Bool) {
    isMobileAdsStarted = started
    if started && !isLoading && !isAdReady {
      loadAd()
    }
  }

  func loadAd() {
    guard !isLoading && isMobileAdsStarted else {
      print("⏳ Cannot load ad: SDK not started or already loading")
      return
    }

    isLoading = true
    isAdReady = false

    Task {
      do {
        let request = Request()

        // Configure request based on tracking authorization
        if ATTrackingManager.trackingAuthorizationStatus != .authorized {
          // User has denied tracking - request non-personalized ads
          let extras = Extras()
          extras.additionalParameters = ["npa": "1"]  // Non-personalized ads
          request.register(extras)
          print("🔒 Requesting non-personalized ads due to tracking denial")
        } else {
          print("🎯 Requesting personalized ads - tracking authorized")
        }

        interstitialAd = try await InterstitialAd.load(
          with: adUnitID, request: request)
        await MainActor.run {
          interstitialAd?.fullScreenContentDelegate = self
          isLoading = false
          isAdReady = true
          print("✅ Interstitial ad loaded successfully")
        }
      } catch {
        await MainActor.run {
          isLoading = false
          isAdReady = false
          print("❌ Failed to load interstitial ad with error: \(error.localizedDescription)")
        }
      }
    }
  }

  func showAd() {
    guard let interstitialAd = interstitialAd, isAdReady else {
      print("❌ Interstitial ad wasn't ready")
      // Try to load a new ad for next time
      loadAd()
      return
    }

    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first
    else {
      print("❌ Could not find window to present ad")
      return
    }

    guard let rootViewController = window.rootViewController else {
      print("❌ Could not find root view controller")
      return
    }

    interstitialAd.present(from: rootViewController)
  }
}

// MARK: - FullScreenContentDelegate
extension InterstitialAdManager: FullScreenContentDelegate {
  func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
    print("🎯 Interstitial ad did record impression")
  }

  func adDidRecordClick(_ ad: FullScreenPresentingAd) {
    print("👆 Interstitial ad did record click")
  }

  func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
    print("❌ Interstitial ad failed to present with error: \(error.localizedDescription)")
    // Load a new ad for next time
    loadAd()
  }

  func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
    print("📺 Interstitial ad will present full screen content")
  }

  func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
    print("📱 Interstitial ad will dismiss full screen content")
  }

  func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
    print("✅ Interstitial ad did dismiss full screen content")
    // Clear the interstitial ad and load a new one for next time
    interstitialAd = nil
    isAdReady = false
    loadAd()
  }
}
