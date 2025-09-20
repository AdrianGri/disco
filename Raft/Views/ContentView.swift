//
//  ContentView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-07-19.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var appState: AppState
  @StateObject private var viewModel = DiscountCodeViewModel()
  @State private var manualDomain: String = ""
  @State private var navigationPath = NavigationPath()
  @State private var showPremiumUpgrade = false
  @State private var tutorialOpacity: Double = 0

  var body: some View {
    ZStack {
      NavigationStack(path: $navigationPath) {
        SearchView(
          manualDomain: $manualDomain,
          onUpgradePressed: { showPremiumUpgrade = true },
          onTutorialPressed: { appState.resetTutorialState() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea(.all))
        .navigationDestination(for: String.self) { domain in
          CodesView(domain: domain, viewModel: viewModel) {
            appState.clearDomainFromDeepLink()
            viewModel.clearCodes()
            manualDomain = ""
          }
        }
        .onChange(of: appState.domainFromDeepLink) { domain in
          if let domain = domain {
            navigationPath.append(domain)
            viewModel.fetchCodes(for: domain)
          }
        }
        .sheet(isPresented: $showPremiumUpgrade) {
          PremiumUpgradeView()
            .environmentObject(appState)
        }
      }

      // Tutorial overlay
      TutorialView(
        isPresented: .init(
          get: { appState.showTutorial },
          set: { _ in
            // Handle fade-out animation here
            withAnimation(.easeOut(duration: 0.3)) {
              tutorialOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
              appState.markTutorialAsSeen()
              // After tutorial is dismissed, request ATT then start ads
              Task {
                await appState.requestTrackingPermissionIfNeeded()
                appState.startMobileAds()
              }
            }
          }
        )
      )
      .opacity(tutorialOpacity)
      .zIndex(appState.showTutorial ? 1 : -1)
      .allowsHitTesting(tutorialOpacity > 0)
      .onChange(of: appState.showTutorial) { newValue in
        if newValue {
          // Immediately show without fade-in
          tutorialOpacity = 1
        }
        // Don't handle false case here since button dismissal handles it
      }
    }
    .onAppear {
      // Check if this is the first launch
      appState.checkIfFirstLaunch()

      // Set initial tutorial opacity based on showTutorial state
      tutorialOpacity = appState.showTutorial ? 1 : 0

      // If tutorial is not being shown (user has seen it), request ATT now and start ads
      if !appState.showTutorial {
        Task {
          await appState.requestTrackingPermissionIfNeeded()
          appState.startMobileAds()
        }
      }

      if appState.isMobileAdsStarted {
        viewModel.setMobileAdsStarted(true)
      }
      // Pass premium status to view model
      viewModel.isPremium = appState.purchaseManager.isPremium
    }
    .onChange(of: appState.isMobileAdsStarted) { isStarted in
      if isStarted {
        viewModel.setMobileAdsStarted(true)
      }
    }
    .onChange(of: appState.purchaseManager.isPremium) { isPremium in
      viewModel.isPremium = isPremium
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(AppState())
}
