import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI

@MainActor
class AppState: ObservableObject {
  @Published private(set) var domainFromDeepLink: String? = nil
  @Published var isMobileAdsStarted = false
  @Published var showTutorial = false
  let purchaseManager = InAppPurchaseManager()
  let privacyManager = PrivacyManager()

  private let hasSeenTutorialKey = "hasSeenTutorial"

  private func extractMainDomain(from domain: String) -> String {
    let components = domain.components(separatedBy: ".")

    // If there are less than 2 components, return the original domain
    guard components.count >= 2 else {
      return domain
    }

    // For domains like "nike.com", "checkout.nike.com", "shop.nike.com"
    // We want to return "nike.com" (last two components)
    let mainDomainComponents = Array(components.suffix(2))
    return mainDomainComponents.joined(separator: ".")
  }

  func setDomainFromDeepLink(_ domain: String) {
    let mainDomain = extractMainDomain(from: domain)
    domainFromDeepLink = mainDomain
    print("🌐 Extracted and set main domain: \(mainDomain) (from: \(domain))")
  }

  func clearDomainFromDeepLink() {
    domainFromDeepLink = nil
    print("🧹 Cleared domain from deep link")
  }

  func startMobileAds() {
    guard !isMobileAdsStarted else { return }

    MobileAds.shared.start { [weak self] _ in
      DispatchQueue.main.async {
        self?.isMobileAdsStarted = true
        print("✅ Google Mobile Ads SDK started successfully")
      }
    }
  }

  func requestTrackingPermissionIfNeeded() async {
    await privacyManager.requestTrackingPermission()
  }

  func checkIfFirstLaunch() {
    let hasSeenTutorial = UserDefaults.standard.bool(forKey: hasSeenTutorialKey)
    showTutorial = !hasSeenTutorial
  }

  func markTutorialAsSeen() {
    UserDefaults.standard.set(true, forKey: hasSeenTutorialKey)
    showTutorial = false
  }

  // For testing purposes - reset the tutorial state
  func resetTutorialState() {
    UserDefaults.standard.removeObject(forKey: hasSeenTutorialKey)
    showTutorial = true
  }
}

@main
struct RaftApp: App {
  @StateObject private var appState = AppState()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(appState)
        .font(.custom("Avenir", size: 16))
        .onOpenURL { url in
          if url.scheme == "disco", url.host == "showcodes" {
            print("📦 Deep link triggered: \(url)")
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let domain = components.queryItems?.first(where: { $0.name == "domain" })?.value
            {
              appState.setDomainFromDeepLink(domain)
            }
          }
        }
        .onAppear {
          // ATT prompt is now shown after the tutorial is dismissed (see ContentView)
        }
    }
  }
}
