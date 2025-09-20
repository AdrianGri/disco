//
//  SearchHeaderView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-01.
//

import SwiftUI

struct SearchHeaderView: View {
  let isKeyboardVisible: Bool
  let onUpgradePressed: () -> Void
  let onTutorialPressed: () -> Void
  @ObservedObject var purchaseManager: InAppPurchaseManager
  @State private var showingMenu = false

  var body: some View {
    VStack(spacing: 20) {
      if !isKeyboardVisible {
        // Logo centered with menu on the right
        ZStack {
          Image("LogoTransparent")
            .resizable()
            .renderingMode(.original)
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: 150, height: 150)
            .transition(.opacity)

          HStack {
            Spacer()

            VStack {
              Menu {
                // Premium status or upgrade option
                if purchaseManager.isPremium {
                  // Show premium status (non-interactive)
                  Label {
                    Text("Premium Active")
                      .foregroundColor(.primary)
                  } icon: {
                    Image(systemName: "crown.fill")
                      .foregroundColor(.yellow)
                  }

                  Divider()
                } else {
                  // Show upgrade option
                  Button {
                    onUpgradePressed()
                  } label: {
                    Label {
                      Text("Upgrade to Premium")
                    } icon: {
                      Image(systemName: "crown.fill")
                        .foregroundColor(.blue)
                    }
                  }

                  Divider()
                }

                Button("Privacy Policy") {
                  openPrivacyPolicy()
                }

                Button("Tutorial") {
                  onTutorialPressed()
                }

                Button("Support") {
                  openSupport()
                }

                #if DEBUG
                  Divider()

                  Button("🔧 Toggle Premium (Debug)") {
                    purchaseManager.debugTogglePremium()
                  }
                #endif
              } label: {
                Image(systemName: "line.3.horizontal")
                  .font(.title2)
                  .foregroundColor(.black)
                  .frame(minWidth: 50, minHeight: 50)
                  .contentShape(Rectangle())
              }

              Spacer()
            }
          }
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Start saving money\nat your favorite stores!")
          .font(.custom("Avenir", size: 32))
          .fontWeight(.heavy)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
          .allowsHitTesting(false)

        // Premium badge for premium users
        if purchaseManager.isPremium {
          HStack(spacing: 6) {
            Image(systemName: "crown.fill")
              .font(.caption)
              .foregroundColor(.yellow)
            Text("Premium")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.primary)
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(
            ZStack {
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
              RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            }
          )
        }
      }
    }
  }

  private func openPrivacyPolicy() {
    if let url = URL(
      string:
        "https://docs.google.com/document/d/e/2PACX-1vS4Z1X3-bk94k_YfG8nHQZWkVV23Qq3lEEaYbGyamlJd1Bmv2ktrOg55JZqFqZEf09aSF3egRoPJdf7/pub"
    ) {
      UIApplication.shared.open(url)
    }
  }

  private func openSupport() {
    if let url = URL(string: "https://tally.so/r/3jKZaE") {
      UIApplication.shared.open(url)
    }
  }
}

#Preview {
  SearchHeaderView(
    isKeyboardVisible: false,
    onUpgradePressed: {},
    onTutorialPressed: {},
    purchaseManager: InAppPurchaseManager()
  )
}
