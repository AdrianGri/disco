import SwiftUI
import GoogleMobileAds

class AppState: ObservableObject {
    @Published var domainFromDeepLink: String? = nil
    @Published var isMobileAdsStarted = false
    
    func startMobileAds() {
        guard !isMobileAdsStarted else { return }
        
        MobileAds.shared.start { [weak self] _ in
            DispatchQueue.main.async {
                self?.isMobileAdsStarted = true
                print("✅ Google Mobile Ads SDK started successfully")
            }
        }
    }
}

@main
struct RaftApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    if url.scheme == "raft", url.host == "showcodes" {
                        print("📦 Deep link triggered: \(url)")
                        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                           let domain = components.queryItems?.first(where: { $0.name == "domain" })?.value {
                            appState.domainFromDeepLink = domain
                            print("🌐 Extracted domain: \(domain)")
                        }
                    }
                }
                .onAppear {
                    appState.startMobileAds()
                }
        }
    }
}
