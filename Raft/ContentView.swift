//
//  ContentView.swift
//  Raft
//
//  Created by Adrian Gri on 2025-07-19.
//


import SwiftUI
import GoogleMobileAds

struct PromptRequest: Codable {
    let prompt: String
}


struct CodeInfo: Codable, Identifiable {
    let id = UUID()
    let code: String
    let description: String
    let conditions: String
    let has_description: Bool
    let has_conditions: Bool
}

struct DetailedCodesResponse: Codable {
    let codes: [CodeInfo]
}

struct CodeRowView: View {
    let codeInfo: CodeInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(codeInfo.code)
                .font(.title2)
                .bold()

            if codeInfo.has_description {
                Text(codeInfo.description)
                    .foregroundColor(.primary)
            } else {
                Text("Discount amount unknown")
                    .foregroundColor(.secondary)
                    .italic()
            }

            if codeInfo.has_conditions {
                Text(codeInfo.conditions)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Conditions not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 6)
    }
}

let appGroupID = "group.com.yourcompany.raft"

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var interstitialAdManager = InterstitialAdManager()
    @State private var codes: [CodeInfo] = []
    @State private var manualDomain: String = ""

    var body: some View {
        NavigationView {
            VStack {
                if let domain = appState.domainFromDeepLink {
                    Text("Discount Codes for \(domain)")
                        .font(.headline)
                        .padding()

                    if codes.isEmpty {
                        ProgressView("Loading...")
                            .padding()
                    } else {
                        List(codes) { code in
                            VStack(alignment: .leading) {
                                CodeRowView(codeInfo: code)
                                HStack {
                                    Spacer()
                                    Button("Copy Code") {
                                        UIPasteboard.general.string = code.code
                                    }
                                    .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else {
                    VStack {
                        Text("Enter a website to find discount codes")
                            .font(.headline)
                            .padding(.bottom, 8)

                        TextField("example.com", text: $manualDomain)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .autocapitalization(.none)

                        Button("Find Codes") {
                            appState.domainFromDeepLink = manualDomain
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Raft")
            .onAppear {
                // Pre-load an interstitial ad when the view appears
                interstitialAdManager.loadAd()
            }
            .toolbar {
                if !codes.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            appState.domainFromDeepLink = nil
                            codes = []
                        }
                    }
                }
            }
        }
        .task(id: appState.domainFromDeepLink) {
            guard let domain = appState.domainFromDeepLink else {
                print("❗️ No domain to load")
                return
            }
            print("🟡 .task triggered for domain: \(domain)")
            
            codes = [] // Clear existing codes to show loading spinner
            
            // Show interstitial ad when loading starts (small delay to ensure UI is ready)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if interstitialAdManager.isAdReady {
                    interstitialAdManager.showAd()
                } else {
                    print("📢 Ad not ready, loading new ad for next time")
                    interstitialAdManager.loadAd()
                }
            }

            let prompt = "Find current discount codes for \(domain)"
            guard let url = URL(string: "https://disco-backend.vercel.app/codes-detailed") else {
                print("❌ Invalid backend URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                request.httpBody = try JSONEncoder().encode(PromptRequest(prompt: prompt))
                print("✅ Request body encoded successfully")
            } catch {
                print("❌ Failed to encode prompt: \(error)")
                return
            }

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Network error: \(error)")
                    return
                }

                guard let data = data else {
                    print("❌ No data returned from server")
                    return
                }

                print("📬 Response received. Attempting to decode...")

                do {
                    let decoded = try JSONDecoder().decode(DetailedCodesResponse.self, from: data)
                    DispatchQueue.main.async {
                        print("✅ Codes decoded: \(decoded.codes)")
                        codes = decoded.codes
                    }
                } catch {
                    print("❌ Failed to decode response: \(error)")
                    if let raw = String(data: data, encoding: .utf8) {
                        print("📄 Raw response: \(raw)")
                    }
                }
            }.resume()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
