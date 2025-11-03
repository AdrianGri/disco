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

  var body: some View {
    ZStack {
      NavigationStack(path: $navigationPath) {
        SearchView(
          manualDomain: $manualDomain,
          // onUpgradePressed: { showPremiumUpgrade = true },
          onTutorialPressed: { appState.resetTutorialState() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea(.all))
        .navigationDestination(for: String.self) { domain in
          CodesView(domain: domain, viewModel: viewModel)
            .onAppear {
              // Clear state when CodesView appears to prepare for next search
              appState.clearDomainFromDeepLink()
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
    }
    .onAppear {
      // Check if this is the first launch
      appState.checkIfFirstLaunch()

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
    .sheet(
      isPresented: .init(
        get: { appState.showTutorial },
        set: { appState.showTutorial = $0 }
      )
    ) {
      TutorialView()
        .environmentObject(appState)
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(AppState())
}
