//
//  ContentView.swift
//  Raft
//
//  Created by Adrian Gri on 2025-07-19.
//

import SwiftUI

let appGroupID = "group.com.yourcompany.raft"

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DiscountCodeViewModel()
    @State private var manualDomain: String = ""

    var body: some View {
        NavigationView {
            VStack {
                if let domain = appState.domainFromDeepLink {
                    codesView(for: domain)
                } else {
                    searchView
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
    
    // MARK: - Views
    
    @ViewBuilder
    private func codesView(for domain: String) -> some View {
        Text("Discount Codes for \(domain)")
            .font(.headline)
            .foregroundColor(.appAccent)
            .padding()

        if viewModel.isLoading {
            ProgressView("Loading...")
                .padding()
        } else if let errorMessage = viewModel.errorMessage {
            VStack {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.appAccent)
                    .padding()
                Button("Try Again") {
                    viewModel.fetchCodes(for: domain)
                }
                .foregroundColor(.white)
                .padding()
            }
        } else if viewModel.codes.isEmpty {
            Text("No codes found")
                .foregroundColor(.appPrimary)
                .padding()
        } else {
            List(viewModel.codes) { code in
                CodeRowView(codeInfo: code) { codeString in
                    viewModel.copyCode(codeString)
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
    
    private var searchView: some View {
        VStack(spacing: 15) {
            Text("Enter a website to find discount codes")
                .font(.headline)
                .foregroundColor(.appAccent)

            TextField("example.com", text: $manualDomain)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)

            Button("Find Codes") {
                appState.domainFromDeepLink = manualDomain.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .foregroundColor(.appSurface)
            .padding(.vertical, 12)
            .padding(.horizontal, 30)
            .background(.appAccent)
            .clipShape(Capsule())
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
