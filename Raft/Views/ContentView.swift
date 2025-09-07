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
    NavigationStack(path: $navigationPath) {
      SearchView(
        manualDomain: $manualDomain,
        onUpgradePressed: { showPremiumUpgrade = true }
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.appBackground.ignoresSafeArea(.all))
      .navigationDestination(for: String.self) { domain in
        CodesView(domain: domain, viewModel: viewModel) {
          appState.domainFromDeepLink = nil
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
    .onAppear {
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
