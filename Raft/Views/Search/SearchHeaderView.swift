//
//  SearchHeaderView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-01.
//

import SwiftUI

struct SearchHeaderView: View {
  let isKeyboardVisible: Bool
  @State private var showingMenu = false

  var body: some View {
    VStack(spacing: 20) {
      if !isKeyboardVisible {
        // Logo centered with menu on the right
        ZStack {
          // Centered logo
          Image("LogoTransparent")
            .resizable()
            .renderingMode(.original)
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: 150, height: 150)
            .transition(.opacity)

          // Menu button aligned to trailing edge
          HStack {
            Spacer()

            VStack {
              Menu {
                Button("Privacy Policy") {
                  openPrivacyPolicy()
                }

                Button("Support") {
                  openSupport()
                }
              } label: {
                Image(systemName: "line.3.horizontal")
                  .font(.title2)
                  .foregroundColor(.black)
              }

              Spacer()
            }
          }
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
      }

      Text("Start saving money\nat your favorite stores!")
        .font(.custom("Avenir", size: 32))
        .fontWeight(.heavy)
        .foregroundColor(.black)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .allowsHitTesting(false)
    }
  }

  private func openPrivacyPolicy() {
    // Add your privacy policy URL here
    if let url = URL(string: "https://docs.google.com/document/d/e/2PACX-1vS4Z1X3-bk94k_YfG8nHQZWkVV23Qq3lEEaYbGyamlJd1Bmv2ktrOg55JZqFqZEf09aSF3egRoPJdf7/pub") {
      UIApplication.shared.open(url)
    }
  }

  private func openSupport() {
    // Add your support URL or email here
    if let url = URL(string: "mailto:support@yourapp.com") {
      UIApplication.shared.open(url)
    }
  }
}

#Preview {
  SearchHeaderView(isKeyboardVisible: false)
}
