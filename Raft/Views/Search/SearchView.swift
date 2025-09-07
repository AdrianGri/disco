//
//  SearchView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-01.
//

import SwiftUI

struct SearchView: View {
  @EnvironmentObject var appState: AppState
  @Binding var manualDomain: String
  @State private var isKeyboardVisible = false
  let onUpgradePressed: () -> Void

  var body: some View {
    ZStack {
      Color.appBackground
        .ignoresSafeArea(.all)
        .contentShape(Rectangle())
        .onTapGesture {
          UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

      VStack(spacing: 20) {
        SearchHeaderView(
          isKeyboardVisible: isKeyboardVisible,
          onUpgradePressed: onUpgradePressed,
          purchaseManager: appState.purchaseManager
        )

        SearchInputView(manualDomain: $manualDomain) {
          performSearch()
        }

        SearchButtonView {
          performSearch()
        }

        TryButtonsView { domain in
          appState.domainFromDeepLink = domain
          UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        if !isKeyboardVisible {
          Spacer()

          HowItWorksView()
        }
      }
      .padding(.horizontal)
    }
    .onAppear {
      setupKeyboardObservers()
    }
    .onDisappear {
      removeKeyboardObservers()
    }
    .animation(.bouncy(duration: 0.4), value: isKeyboardVisible)
  }

  private func performSearch() {
    // Dismiss keyboard first
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

    let trimmedDomain = manualDomain.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedDomain.isEmpty {
      appState.domainFromDeepLink = trimmedDomain
    }
  }

  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillShowNotification,
      object: nil,
      queue: .main
    ) { _ in
      isKeyboardVisible = true
    }

    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillHideNotification,
      object: nil,
      queue: .main
    ) { _ in
      isKeyboardVisible = false
    }
  }

  private func removeKeyboardObservers() {
    NotificationCenter.default.removeObserver(
      self, name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.removeObserver(
      self, name: UIResponder.keyboardWillHideNotification, object: nil)
  }
}

#Preview {
  SearchView(manualDomain: .constant(""), onUpgradePressed: {})
    .environmentObject(AppState())
}
