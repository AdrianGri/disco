//
//  PrivacyManager.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-20.
//

import AdSupport
import AppTrackingTransparency
import Foundation

@MainActor
class PrivacyManager: ObservableObject {
  @Published var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined

  init() {
    updateTrackingStatus()
  }

  func requestTrackingPermission() async {
    // Check the current system status, not our cached property
    let currentStatus = ATTrackingManager.trackingAuthorizationStatus

    // Only request if status is not determined
    guard currentStatus == .notDetermined else {
      print("🔄 ATT already determined: \(currentStatus)")
      trackingAuthorizationStatus = currentStatus
      return
    }

    print("📋 Requesting ATT permission...")
    let status = await ATTrackingManager.requestTrackingAuthorization()
    trackingAuthorizationStatus = status

    // Log the result
    switch status {
    case .authorized:
      print("🟢 Tracking authorized - can use IDFA")
    case .denied:
      print("🔴 Tracking denied - cannot use IDFA")
    case .restricted:
      print("🟡 Tracking restricted")
    case .notDetermined:
      print("⚪ Tracking not determined")
    @unknown default:
      print("❓ Unknown tracking status")
    }
  }

  private func updateTrackingStatus() {
    trackingAuthorizationStatus = ATTrackingManager.trackingAuthorizationStatus
  }

  // Returns whether personalized ads can be shown
  var canShowPersonalizedAds: Bool {
    return trackingAuthorizationStatus == .authorized
  }

  // Returns the IDFA if tracking is authorized, nil otherwise
  var advertisingIdentifier: String? {
    guard trackingAuthorizationStatus == .authorized else { return nil }
    let idfa = ASIdentifierManager.shared().advertisingIdentifier
    return idfa != UUID(uuidString: "00000000-0000-0000-0000-000000000000") ? idfa.uuidString : nil
  }
}
