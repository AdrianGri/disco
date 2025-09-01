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

  var body: some View {
    ZStack {
      // Always show SearchView as the base layer
      SearchView(manualDomain: $manualDomain)

      // Show CodesView on top when there's a domain
      if let domain = appState.domainFromDeepLink {
        CodesView(domain: domain, viewModel: viewModel) {
          appState.domainFromDeepLink = nil
          viewModel.clearCodes()
          manualDomain = ""
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground.ignoresSafeArea(.all))
    .onAppear {
      if appState.isMobileAdsStarted {
        viewModel.setMobileAdsStarted(true)
      }
    }
    .onChange(of: appState.isMobileAdsStarted) { isStarted in
      if isStarted {
        viewModel.setMobileAdsStarted(true)
      }
    }
    .toolbar {
      if !viewModel.codes.isEmpty {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") {
            appState.domainFromDeepLink = nil
            viewModel.clearCodes()
            manualDomain = ""  // Clear the text field when returning to SearchView
          }
        }
      }
    }
    .onChange(of: appState.domainFromDeepLink) { domain in
      if let domain = domain {
        viewModel.fetchCodes(for: domain)
      }
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(AppState())
}
