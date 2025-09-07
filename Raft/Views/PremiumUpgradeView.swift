//
//  PremiumUpgradeView.swift
//  Disco
//
//  Created on 2025-09-06.
//

import SwiftUI

struct PremiumUpgradeView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  
  private var purchaseManager: InAppPurchaseManager {
    appState.purchaseManager
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 30) {
        // Header
        VStack(spacing: 16) {
          Image(systemName: "crown.fill")
            .font(.system(size: 60))
            .foregroundColor(.yellow)
          
          Text("Upgrade to Premium")
            .font(.title)
            .fontWeight(.bold)
          
          Text("Enjoy an ad-free experience")
            .font(.title3)
            .foregroundColor(.secondary)
        }
        .padding(.top, 40)
        
        // Features
        VStack(alignment: .leading, spacing: 20) {
          FeatureRow(
            icon: "xmark.circle.fill",
            title: "No Ads",
            description: "Remove all advertisements"
          )
          
          FeatureRow(
            icon: "bolt.fill",
            title: "Faster Experience",
            description: "Get discount codes faster for popular sites"
          )
          
          FeatureRow(
            icon: "heart.fill",
            title: "Support Development",
            description: "Help us improve the app"
          )
        }
        .padding(.horizontal, 20)
        
        Spacer()
        
        // Purchase Section
        VStack(spacing: 16) {
          if purchaseManager.isLoading {
            ProgressView("Loading...")
              .scaleEffect(1.2)
          } else {
            // Purchase Button
            Button(action: {
              print("🔧 Purchase button tapped in PremiumUpgradeView")
              Task {
                // Try to load products first if none are available
                if purchaseManager.products.isEmpty {
                  await purchaseManager.loadProducts()
                }
                print("🔧 Calling purchasePremium...")
                await purchaseManager.purchasePremium()
                print("🔧 purchasePremium completed")
                
                // Check if premium status changed and dismiss
                await MainActor.run {
                  print("🔍 After purchase - isPremium: \(purchaseManager.isPremium)")
                  if purchaseManager.isPremium {
                    print("🔍 Dismissing modal after successful purchase")
                    dismiss()
                  }
                }
              }
            }) {
              VStack(spacing: 4) {
                Text("Get Premium")
                  .font(.title2)
                  .fontWeight(.semibold)
                Text("One-time purchase • \(purchaseManager.getPremiumPrice())")
                  .font(.caption)
                  .opacity(0.8)
              }
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
              .background(Color.blue)
              .cornerRadius(12)
            }
            // Remove the disabled state since debug mode will work even without products
            // .disabled(purchaseManager.products.isEmpty)
            
            // Restore Button
            Button("Restore Purchases") {
              Task {
                await purchaseManager.restorePurchases()
              }
            }
            .foregroundColor(.blue)
          }
          
          // Error Message
          if let error = purchaseManager.purchaseError {
            Text(error)
              .foregroundColor(.red)
              .font(.caption)
              .multilineTextAlignment(.center)
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") {
            dismiss()
          }
        }
      }
    }
    .task {
      await purchaseManager.loadProducts()
    }
    .onReceive(appState.purchaseManager.$isPremium) { isPremium in
      print("🔍 PremiumUpgradeView: isPremium received: \(isPremium)")
      if isPremium {
        print("🔍 PremiumUpgradeView: Dismissing modal...")
        DispatchQueue.main.async {
          dismiss()
        }
      }
    }
  }
}

struct FeatureRow: View {
  let icon: String
  let title: String
  let description: String
  
  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.blue)
        .frame(width: 30)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.headline)
        Text(description)
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      
      Spacer()
    }
  }
}

#Preview {
  PremiumUpgradeView()
    .environmentObject(AppState())
}
